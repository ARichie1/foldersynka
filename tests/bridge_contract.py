#!/usr/bin/env python3
"""Offline public-router contract: python3 tests/bridge_contract.py."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BridgeContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='foldersynka-contract-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source with spaces'
        self.destination = self.root / 'destination with spaces'
        for path in (self.source, self.destination, self.root / 'home', self.root / 'prefix'):
            path.mkdir()
        self.env = {**os.environ, 'HOME': str(self.root / 'home'),
                    'PREFIX': str(self.root / 'prefix'), 'FS_HOME': str(ROOT),
                    'FS_RUNTIME': str(self.root / 'home' / '.foldersynka')}

    def command(self, *args, codes=(0,)):
        result = subprocess.run(['bash', str(ROOT / 'core/cli/router.sh'), *args],
                                env=self.env, capture_output=True, text=True, timeout=20)
        self.assertIn(result.returncode, codes, f'{args}: {result.stdout}\n{result.stderr}')
        try:
            value = json.loads(result.stdout)
        except ValueError:
            self.fail(f'{args} did not emit one JSON document: {result.stdout!r}\n{result.stderr}')
        self.assertIsInstance(value, dict)
        self.assertEqual(value.get('schemaVersion'), 1)
        self.assertEqual(value.get('ok'), result.returncode == 0)
        return value

    def create(self):
        return self.command('create', 'contract', '--src', str(self.source),
                            '--dest', str(self.destination), '--mode', 'bidirectional', '--json')

    def sync(self):
        return self.command('sync', 'contract', '--once', '--json')

    def test_json_and_two_way_convergence(self):
        self.command('capabilities', '--json')
        (self.source / 'seed.txt').write_text('initial\n')
        self.create()
        self.command('inspect', 'contract', '--json')
        self.command('plan', 'contract', '--json')
        self.assertFalse((self.destination / 'seed.txt').exists(), 'plan must not copy files')
        self.sync()
        self.assertEqual((self.destination / 'seed.txt').read_text(), 'initial\n')
        (self.source / 'seed.txt').write_text('source edit\n')
        self.sync()
        self.assertEqual((self.destination / 'seed.txt').read_text(), 'source edit\n')
        (self.destination / 'seed.txt').write_text('destination edit\n')
        self.sync()
        self.assertEqual((self.source / 'seed.txt').read_text(), 'destination edit\n')
        self.sync()
        self.assertEqual((self.destination / 'seed.txt').read_text(), 'destination edit\n')

    def test_divergence_is_preserved_and_reported(self):
        (self.source / 'shared.txt').write_text('base\n')
        self.create()
        self.sync()
        (self.source / 'shared.txt').write_text('left version\n')
        (self.destination / 'shared.txt').write_text('right version\n')
        self.command('sync', 'contract', '--once', '--json', codes=(4,))
        self.assertEqual((self.source / 'shared.txt').read_text(), 'left version\n')
        self.assertEqual((self.destination / 'shared.txt').read_text(), 'right version\n')
        conflicts = self.command('conflicts', 'contract', '--json', codes=(4,))
        self.assertIn('shared.txt', json.dumps(conflicts), 'divergence must be discoverable')


if __name__ == '__main__':
    unittest.main(verbosity=2)
