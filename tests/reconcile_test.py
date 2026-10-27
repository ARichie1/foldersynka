import importlib.util
from pathlib import Path
import tempfile
import types
import unittest

spec = importlib.util.spec_from_file_location('reconcile', Path(__file__).parents[1] / 'core/engine/reconcile.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class ReconcileTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.a, self.b = self.root / 'a', self.root / 'b'
        self.a.mkdir(); self.b.mkdir()
        self.e = m.Engine(self.a, self.b, self.root / 'state', 'bidirectional')
        self.args = types.SimpleNamespace(path='f', take='a')

    def run_sync(self):
        return self.e.run('sync', self.args)

    def seed(self):
        (self.a / 'f').write_text('old')
        self.assertEqual(self.run_sync()[1], 0)

    def test_same_size_edits(self):
        self.seed()
        (self.b / 'f').write_text('new')
        self.run_sync()
        self.assertEqual((self.a / 'f').read_text(), 'new')

    def test_initial_divergence_and_resolution_retention(self):
        (self.a / 'f').write_text('aaa'); (self.b / 'f').write_text('bbb')
        self.assertEqual(self.run_sync()[1], 4)
        self.assertEqual((self.b / 'f').read_text(), 'bbb')
        self.assertEqual(self.e.run('resolve', self.args)[1], 0)
        self.assertEqual((self.b / 'f').read_text(), 'aaa')
        self.assertEqual((self.e.state / 'objects' / m.hashlib.sha256(b'bbb').hexdigest()).read_bytes(), b'bbb')

    def test_delete_vs_edit(self):
        self.seed(); (self.a / 'f').unlink(); (self.b / 'f').write_text('new')
        self.assertEqual(self.run_sync()[1], 4)
        self.assertEqual((self.b / 'f').read_text(), 'new')

    def test_delete_unchanged(self):
        self.seed(); (self.a / 'f').unlink(); self.run_sync()
        self.assertFalse((self.b / 'f').exists())

    def test_unavailable(self):
        self.seed(); self.a.rename(self.root / 'gone')
        with self.assertRaises(ValueError): self.run_sync()
        self.assertTrue((self.b / 'f').exists())

    def test_collision(self):
        (self.a / 'f').mkdir(); (self.a / 'f' / 'child').write_text('safe')
        (self.b / 'f').write_text('safe')
        self.assertEqual(self.run_sync()[1], 4)
        self.assertFalse((self.b / 'child').exists())

    def test_copy_and_mirror(self):
        (self.b / 'extra').write_text('keep')
        self.e.mode = 'copy'; self.run_sync()
        self.assertTrue((self.b / 'extra').exists())
        self.e = m.Engine(self.a, self.b, self.root / 'mirror', 'mirror'); self.run_sync()
        self.assertFalse((self.b / 'extra').exists())

    def test_precondition(self):
        self.seed(); (self.a / 'f').write_text('new')
        _, actions, _ = self.e.plan(self.e.load())
        (self.b / 'f').write_text('concurrent')
        with self.assertRaises(ValueError): self.e.apply(actions[0])
        self.assertEqual((self.b / 'f').read_text(), 'concurrent')

    def test_corrupt_baseline(self):
        self.seed(); (self.e.state / 'baseline.json').write_text('{')
        with self.assertRaises(ValueError): self.run_sync()

    def test_unsafe_baseline(self):
        self.seed()
        import json
        data = self.e.load()
        data['baseline']['../../escape'] = '0' * 64
        (self.e.state / 'baseline.json').write_text(json.dumps(data))
        with self.assertRaises(ValueError): self.run_sync()

    def test_replaced_root(self):
        self.seed()
        self.a.rename(self.root / 'gone'); self.a.mkdir()
        with self.assertRaises(ValueError): self.run_sync()
        self.assertTrue((self.b / 'f').exists())

    def test_hard_excludes(self):
        (self.a / '.git').mkdir(); (self.a / '.git' / 'config').write_text('secret')
        (self.a / '.env').write_text('secret')
        self.run_sync()
        self.assertFalse((self.b / '.git').exists())
        self.assertFalse((self.b / '.env').exists())

    def test_partial_apply_recovery(self):
        self.seed()
        (self.a / 'f').unlink()
        (self.a / 'g').write_text('new')
        _, actions, _ = self.e.plan(self.e.load())
        self.e.apply(actions[0])
        # Simulate process death before baseline commit.
        self.run_sync()
        self.assertFalse((self.b / 'f').exists())
        self.assertEqual((self.b / 'g').read_text(), 'new')

    def test_json_bridge(self):
        import json
        import os
        import subprocess
        home = str(Path(__file__).parents[1])
        env = dict(os.environ, FS_HOME=home, PREFIX=str(self.root), HOME=str(self.root))
        router = ['bash', home + '/core/cli/router.sh']
        commands = [
            ['create', 'demo', '--src', str(self.a), '--dest', str(self.b), '--mode', 'bidirectional', '--json'],
            ['capabilities', '--json'], ['inspect', 'demo', '--json'],
            ['sync', 'demo', '--once', '--json'], ['status', 'demo', '--json'],
            ['plan', 'demo', '--json'], ['conflicts', 'demo', '--json'],
            ['wait', 'demo', '--timeout', '1', '--json']]
        for args in commands:
            response = subprocess.run(router + args, env=env, text=True, capture_output=True)
            self.assertEqual(response.returncode, 0, response.stderr + response.stdout)
            self.assertEqual(json.loads(response.stdout)['schemaVersion'], 1)
        failed = subprocess.run(router + ['create', 'bad', '--unknown', '--json'],
                                env=env, text=True, capture_output=True)
        self.assertEqual(failed.returncode, 2)
        self.assertFalse(json.loads(failed.stdout)['ok'])

    def test_symlink(self):
        (self.a / 'f').symlink_to('/etc/passwd')
        self.assertEqual(self.run_sync()[1], 4)

    def test_bulk_delete_guard(self):
        for i in range(11):
            (self.a / str(i)).write_text('safe')
        self.run_sync()
        for path in self.a.iterdir():
            path.unlink()
        result, code = self.run_sync()
        self.assertEqual(code, 4)
        self.assertEqual(len(list(self.b.iterdir())), 11)
        self.assertTrue(all(c['reason'] == 'bulk_delete_guard' for c in result['conflicts']))
        self.args.allow_large_delete = True
        self.assertEqual(self.run_sync()[1], 0)
        self.assertEqual(list(self.b.iterdir()), [])

    def test_inspection_reports_conflicts_without_blocking_configuration(self):
        (self.a / 'f').write_text('left')
        (self.b / 'f').write_text('right')
        result, code = self.e.run('inspect', self.args)
        self.assertEqual(code, 0)
        self.assertFalse(result['converged'])
        self.assertEqual(len(result['conflicts']), 1)


if __name__ == '__main__':
    unittest.main()
