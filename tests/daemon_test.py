"""Actual Bash daemon lifecycle without a simulated inotify process."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DaemonTests(unittest.TestCase):
    def test_reverse_edits_and_clean_stop(self):
        with tempfile.TemporaryDirectory(prefix='foldersynka-daemon-') as tmp:
            base = Path(tmp)
            a, b = base / 'a', base / 'b'
            for p in (a, b, base / 'home', base / 'prefix'):
                p.mkdir()
            env = {**os.environ, 'HOME': str(base / 'home'), 'PREFIX': str(base / 'prefix'), 'FS_HOME': str(ROOT)}
            created = subprocess.run(['bash', str(ROOT / 'core/cli/router.sh'), 'create', 'demo', '--src', str(a), '--dest', str(b), '--mode', 'bidirectional', '--json'], env=env, capture_output=True, text=True)
            self.assertEqual(created.returncode, 0, created.stderr)
            self.assertTrue(json.loads(created.stdout)['ok'])
            (a / 'file').write_text('initial')
            with (base / 'daemon.log').open('w') as log:
                process = subprocess.Popen(['bash', '-c', 'source "$FS_HOME/core/config/config.sh"; source "$FS_HOME/core/engine/sync-engine.sh"; fs_sync_daemon demo'], env=env, stdout=log, stderr=log)
                try:
                    def wait_for(path, content):
                        deadline = time.monotonic() + 8
                        while time.monotonic() < deadline:
                            if path.exists() and path.read_text() == content:
                                return
                            if process.poll() is not None:
                                break
                            time.sleep(.05)
                        self.fail((base / 'daemon.log').read_text())
                    wait_for(b / 'file', 'initial')
                    (b / 'file').write_text('reverse edit')
                    wait_for(a / 'file', 'reverse edit')
                    process.terminate()
                    self.assertEqual(process.wait(timeout=5), 0)
                    runtime = base / 'home/.foldersynka/state/demo/runtime.conf'
                    self.assertIn('STATUS="stopped"', runtime.read_text())
                    self.assertFalse((base / 'home/.foldersynka/pids/demo.pid').exists())
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.wait(timeout=5)


if __name__ == '__main__':
    unittest.main()
