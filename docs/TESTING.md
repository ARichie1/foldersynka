# Verification

Run from the repository root with Bash, Python 3, rsync and inotifywait available:

```bash
bash tests/test.sh
bash tests/safety.sh
python3 -m unittest discover -s tests -p '*test.py'
python3 tests/bridge_contract.py
```

The original lifecycle suite uses a simulated service supervisor. Python tests exercise real temporary directories and the machine CLI. They do not establish Android shared-storage event behavior or real runit health. Never run sync tests against a real personal project.

Review the newest dated report for exact counts and failures. Complete [device acceptance](DEVICE-ACCEPTANCE.md) before promoting the mobile beta.
