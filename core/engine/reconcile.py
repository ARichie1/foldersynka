#!/usr/bin/env python3
"""Content-based reconciliation. Shell configuration is supplied only via exports.
Exit codes: 0 success, 2 invalid/unavailable, 3 busy, 4 conflicts, 5 failed.
Regular files/directories only; symlinks and type collisions require manual repair.
"""
import argparse
import contextlib
import fcntl
import fnmatch
import hashlib
import json
import os
import re
from pathlib import Path
import stat
import sys
import tempfile
import time


def digest(path):
    h = hashlib.sha256()
    with open(path, 'rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def identity(path):
    try:
        s = path.lstat()
    except FileNotFoundError:
        return None
    if stat.S_ISREG(s.st_mode):
        return digest(path)
    if stat.S_ISDIR(s.st_mode):
        return 'directory'
    return 'unsupported'


def atomic(path, data, precondition=None):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(dir=path.parent, prefix='.reconcile-')
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        if precondition is not None:
            precondition()
        os.replace(name, path)
        d = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(d)
        finally:
            os.close(d)
    finally:
        if os.path.exists(name):
            os.unlink(name)


class Engine:
    def __init__(self, a, b, state, mode='copy', ignore=None):
        self.roots = [Path(a).absolute(), Path(b).absolute()]
        self.state = Path(state).absolute()
        self.mode = mode
        self.patterns = ['.foldersynkaignore', '.git', '.mda', '.env', '.env.*', '*.env', 'node_modules', 'vendor', 'build', 'dist', '.venv', '__pycache__']
        if ignore and Path(ignore).exists():
            self.patterns += [x.strip() for x in Path(ignore).read_text().splitlines()
                              if x.strip() and not x.lstrip().startswith('#')]
        if any(x.startswith('!') for x in self.patterns):
            raise ValueError('Negated ignore rules are unsupported')
        self.validate()
        self.root_ids = self.endpoint_ids()

    def validate(self):
        a, b = [p.resolve() for p in self.roots]
        if a == b or a in b.parents or b in a.parents or a == Path('/') or b == Path('/'):
            raise ValueError('Unsafe overlapping/root endpoints')
        for root in self.roots:
            if not root.is_dir() or root.is_symlink():
                raise ValueError('Endpoint unavailable: ' + str(root))
        if hasattr(self, 'root_ids') and self.endpoint_ids() != self.root_ids:
            raise ValueError('Endpoint replaced during reconciliation')
        if any(r == self.state or r in self.state.parents for r in (a, b)):
            raise ValueError('State must be outside synchronized roots')

    def ignored(self, rel):
        return any(fnmatch.fnmatch(rel, p.rstrip('/').lstrip('/')) or
                   any(fnmatch.fnmatch(c, p.rstrip('/')) for c in rel.split('/'))
                   for p in self.patterns)

    def scan(self, root):
        result = {}
        def walk(folder):
            with os.scandir(folder) as entries:
                for entry in entries:
                    path = Path(entry.path)
                    rel = path.relative_to(root).as_posix()
                    if self.ignored(rel):
                        continue
                    value = identity(path)
                    result[rel] = value
                    if value == 'directory':
                        walk(path)
        walk(root)
        return result

    def endpoint_ids(self):
        return [[r.stat().st_dev, r.stat().st_ino] for r in self.roots]

    def load(self):
        self.validate()
        file = self.state / 'baseline.json'
        if not file.exists():
            return {'schemaVersion': 1, 'baseline': {}, 'roots': [str(p.resolve()) for p in self.roots], 'mode': self.mode, 'endpointIds': self.endpoint_ids()}
        data = json.loads(file.read_text())
        if (not isinstance(data, dict) or data.get('schemaVersion') != 1 or not isinstance(data.get('baseline'), dict)
                or data.get('roots') != [str(p.resolve()) for p in self.roots]
                or data.get('mode') != self.mode
                or data.get('endpointIds') != self.endpoint_ids()):
            raise ValueError('Invalid or incompatible baseline')
        for path, value in data['baseline'].items():
            self.safe_relative(path)
            if not isinstance(value, str) or not re.fullmatch(r'[0-9a-f]{64}', value):
                raise ValueError('Invalid baseline hash')
        return data

    @staticmethod
    def safe_relative(path):
        if (not isinstance(path, str) or not path or path.startswith('/') or
                '\x00' in path or any(p in ('', '.', '..') for p in path.split('/'))):
            raise ValueError('Unsafe baseline path')

    def plan(self, data):
        self.validate()
        scans = [self.scan(r) for r in self.roots]
        actions, conflicts = [], []
        base = data['baseline']
        blocked = []
        for path in sorted(set(base) | set(scans[0]) | set(scans[1])):
            if self.ignored(path) or any(path.startswith(p + '/') for p in blocked):
                continue
            a, b = [s.get(path) for s in scans]
            old = base.get(path)
            reason = None
            if 'unsupported' in (a, b):
                reason = 'unsupported_type'
            elif 'directory' in (a, b):
                if a == b or a is None or b is None:
                    continue
                reason = 'type_collision'
            elif a == b:
                continue
            elif self.mode != 'bidirectional':
                if a is not None:
                    actions.append({'path': path, 'from': 0, 'to': 1, 'expected': [a, b]})
                elif self.mode == 'mirror' and b is not None:
                    actions.append({'path': path, 'from': 0, 'to': 1, 'expected': [a, b]})
            elif a == old:
                actions.append({'path': path, 'from': 1, 'to': 0, 'expected': [a, b]})
            elif b == old:
                actions.append({'path': path, 'from': 0, 'to': 1, 'expected': [a, b]})
            else:
                reason = 'delete_vs_edit' if a is None or b is None else 'divergent_content'
            if reason:
                conflicts.append({'path': path, 'reason': reason, 'expected': [a, b]})
                blocked.append(path)
        return scans, actions, conflicts

    def check(self, path, expected):
        self.validate()
        for root, value in zip(self.roots, expected):
            target = root / path
            if any(p.is_symlink() for p in target.parents if p != root.parent):
                raise ValueError('Symlink parent changed')
            if identity(target) != value:
                raise ValueError('File changed during reconciliation: ' + path)

    def apply(self, action):
        path, expected = action['path'], action['expected']
        self.safe_relative(path)
        self.check(path, expected)
        src = self.roots[action['from']] / path
        dst = self.roots[action['to']] / path
        # Retain every replaced/deleted regular file outside both trees.
        if expected[action['to']] is not None:
            payload = dst.read_bytes()
            if hashlib.sha256(payload).hexdigest() != expected[action['to']]:
                raise ValueError('Destination changed')
            atomic(self.state / 'objects' / expected[action['to']], payload)
        value = expected[action['from']]
        payload = None if value is None else src.read_bytes()
        if payload is not None and hashlib.sha256(payload).hexdigest() != value:
            raise ValueError('Source changed')
        self.check(path, expected)
        if payload is None:
            dst.unlink()
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            self.check(path, expected)
            atomic(dst, payload, lambda: self.check(path, expected))
        # Never commit a false baseline after a concurrent edit.
        if identity(src) != value or identity(dst) != value:
            raise ValueError('Concurrent edit after transfer')

    def run(self, operation, args):
        self.state.mkdir(parents=True, exist_ok=True, mode=0o700)
        with open(self.state / 'lock', 'a') as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return {'error': {'code': 'BUSY'}}, 3
            data = self.load()
            scans, actions, conflicts = self.plan(data)
            deletes = [a for a in actions if a['expected'][a['from']] is None]
            if len(deletes) > 10 and not getattr(args, 'allow_large_delete', False):
                for action in deletes:
                    conflicts.append({'path': action['path'], 'reason': 'bulk_delete_guard', 'expected': action['expected']})
                actions = [a for a in actions if a not in deletes]
            if operation in ('sync', 'wait', 'resolve'):
                # Capture all conflict bytes before any resolution or unrelated apply.
                for conflict in conflicts:
                    for side, value in enumerate(conflict['expected']):
                        if value and value not in ('directory', 'unsupported'):
                            payload = (self.roots[side] / conflict['path']).read_bytes()
                            if hashlib.sha256(payload).hexdigest() != value:
                                raise ValueError('Conflict changed during snapshot')
                            atomic(self.state / 'objects' / value, payload)
                atomic(self.state / 'conflicts.json', json.dumps(conflicts).encode())
            if operation == 'resolve':
                chosen = next((c for c in conflicts if c['path'] == args.path), None)
                if chosen is None:
                    raise ValueError('Path is not a current conflict')
                if chosen['reason'] in ('type_collision', 'unsupported_type', 'bulk_delete_guard'):
                    raise ValueError('Repair unsupported types manually; bulk deletion requires sync --allow-large-delete')
                side = 0 if args.take in ('a', 'source') else 1
                self.apply({'path': args.path, 'from': side, 'to': 1-side, 'expected': chosen['expected']})
                scans, actions, conflicts = self.plan(data)
            if operation in ('sync', 'wait', 'resolve'):
                # Durable intent; recovery re-plans against the last committed baseline.
                atomic(self.state / 'pending.json', json.dumps(actions).encode())
                for action in actions:
                    self.apply(action)
                scans = [self.scan(r) for r in self.roots]
                for path in set(scans[0]) | set(scans[1]) | set(data['baseline']):
                    a, b = [s.get(path) for s in scans]
                    if a == b:
                        if a is None:
                            data['baseline'].pop(path, None)
                        elif a not in ('directory', 'unsupported'):
                            data['baseline'][path] = a
                atomic(self.state / 'baseline.json', json.dumps(data, sort_keys=True).encode())
                atomic(self.state / 'conflicts.json', json.dumps(conflicts).encode())
                (self.state / 'pending.json').unlink(missing_ok=True)
                _, actions, current_conflicts = self.plan(data)
                # Preserve a bulk-deletion hold until a separately authorized pass.
                held = [c for c in conflicts if c['reason'] == 'bulk_delete_guard']
                conflicts = current_conflicts + held
                held_paths = {c['path'] for c in held}
                actions = [a for a in actions if a['path'] not in held_paths]
            revision = hashlib.sha256(json.dumps(scans, sort_keys=True).encode()).hexdigest()
            result = {'mode': self.mode, 'source': str(self.roots[0]), 'destination': str(self.roots[1]),
                      'revision': revision, 'converged': not actions and not conflicts,
                      'actions': actions, 'conflicts': conflicts}
            return result, 4 if conflicts and operation not in ('inspect', 'status') else 0


class JsonParser(argparse.ArgumentParser):
    def error(self, message):
        print(json.dumps({'schemaVersion': 1, 'ok': False,
                          'error': {'code': 'INVALID_ARGUMENT', 'message': message}}))
        self.exit(2)


def main():
    parser = JsonParser()
    parser.add_argument('operation', choices=['capabilities', 'inspect', 'status', 'plan', 'sync', 'wait', 'conflicts', 'resolve'])
    parser.add_argument('profile', nargs='?', default=os.environ.get('FS_PROFILE_NAME', ''))
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--once', action='store_true')
    parser.add_argument('--allow-large-delete', action='store_true', help='Explicitly permit more than ten file deletions in this pass')
    parser.add_argument('--timeout', type=float, default=30)
    parser.add_argument('--path')
    parser.add_argument('--take', choices=['a', 'b', 'source', 'destination'])
    args = parser.parse_args()
    result, code = {}, 0
    try:
        if args.operation == 'capabilities':
            result = {'modes': ['copy', 'mirror', 'bidirectional'], 'commands': ['inspect', 'status', 'plan', 'sync', 'wait', 'conflicts', 'resolve'],
                      'features': ['contentHashes', 'retention', 'polling', 'perFilePreconditions'], 'resolution': '--path PATH --take a|b', 'emptyDirectories': False,
                      'metadataPreservation': False, 'ignoreSyntax': 'glob exclusion only; no negation', 'deleteGuardThreshold': 10,
                      'exitCodes': {'invalid': 2, 'busy': 3, 'conflicts': 4, 'failure': 5}}
        else:
            mode = os.environ.get('FS_PROFILE_MODE', 'copy')
            if mode not in ('copy', 'mirror', 'bidirectional'):
                raise ValueError('Invalid mode')
            if args.operation == 'resolve' and (not args.path or not args.take):
                raise ValueError('resolve requires --path and --take')
            engine = Engine(os.environ['FS_PROFILE_SOURCE'], os.environ['FS_PROFILE_DESTINATION'],
                            os.environ['FS_RECONCILE_STATE'], mode, os.environ.get('FS_RECONCILE_IGNORE'))
            deadline = time.monotonic() + max(0, args.timeout)
            while True:
                result, code = engine.run(args.operation, args)
                if args.operation != 'wait' or code or result['converged']:
                    break
                if time.monotonic() >= deadline:
                    result['error'] = {'code': 'TIMEOUT'}
                    code = 5
                    break
                time.sleep(0.25)
    except (ValueError, KeyError, OSError) as exc:
        result, code = {'error': {'code': 'UNSAFE_OR_UNAVAILABLE', 'message': str(exc)}}, 2
    result.update(schemaVersion=1, operation=args.operation, profile=args.profile, ok=code == 0)
    print(json.dumps(result, ensure_ascii=True))
    return code


if __name__ == '__main__':
    sys.exit(main())
