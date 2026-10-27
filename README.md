# FolderSynka

Safe source-file synchronization for Termux and Android shared storage. This development beta supports **one-way copy**, **one-way mirror**, and **bidirectional** reconciliation. MDA consumes the same public CLI.

## Install once in Termux

```bash
pkg install git python rsync inotify-tools termux-services
termux-setup-storage
git clone https://github.com/ARichie1/foldersynka.git
cd foldersynka
bash install.sh
foldersynka --version
foldersynka capabilities --json
```

Use this updated checkout/archive until the changes are pushed to the repository. Python 3 is now required. Service commands need a running Termux service supervisor; after installing termux-services, restart the Termux session. One-shot sync does not require a supervisor. No root access is needed.

## Choose a mode

| Mode | Behavior |
|---|---|
| `copy` (default) | Source overwrites destination source files; destination-only files remain |
| `mirror` | Source overwrites destination; destination-only source files are deleted with retained bytes |
| `bidirectional` | Compare both sides with the last baseline; preserve divergent edits as conflicts |

Select either physical directory as source for one-way operation. Do not create two reversed mirrors.

```bash
foldersynka create app --src ~/storage/shared/Projects/app --dest ~/projects/app --mode bidirectional
foldersynka plan app --json
foldersynka sync app --once --json
foldersynka start app
foldersynka status app --json
foldersynka stop app
```

The source must exist. Its destination parent must exist; create `~/projects` first if needed. Creating a profile never copies files unless `--watch` is explicitly supplied. Identical/nested/aliased roots and dangerous system roots are rejected. Paths are stored canonically and parsed as data rather than sourced as shell code.

Services reconcile both trees periodically (currently every three seconds). Polling is intentionally used for recovery from missed editor/storage events; large trees need device performance measurement. Service launch is not evidence of completed initial convergence: inspect status or run `wait`.

## Conflicts and recovery

```bash
foldersynka conflicts app --json
foldersynka resolve app --path src/example.ts --take a --json
# a = source; b = destination
foldersynka wait app --timeout 30 --json
```

If both sides changed differently, neither is silently selected. Unrelated files may still converge. Delete-vs-edit is a conflict. Regular-file conflict and replaced/deleted bytes are retained under `~/.foldersynka/state/PROFILE/reconcile/objects/`, keyed by SHA-256. `conflicts.json` maps paths to content hashes; copy the desired object back manually if recovering an older version. Retention currently has no automatic pruning; monitor space. Do not delete state to resolve a conflict.

More than ten planned file deletions in a pass are held by a bulk deletion guard. Inspect the plan, ensure storage is actually available, then explicitly authorize that pass if intended:

```bash
foldersynka sync app --once --allow-large-delete --json
```

A missing/replaced root or invalid baseline fails closed. Ordinary deletions of up to ten files still propagate in mirror/bidirectional mode, with retained bytes. Keep backups of important code. A narrow race remains between external editor writes and final replacement; concurrent editing and physical-device crash behavior remain beta acceptance work.

## Machine contract

Commands: `capabilities`, `inspect`, `status --json`, `plan`, `sync --once`, `wait`, `conflicts`, `resolve`. Responses use schemaVersion 1, ok, operation/profile identity and structured result fields. `inspect`/`status` report conflicts without failing; mutating sync/resolve and plan/conflicts use exit 4 when conflicts remain. Exit 2 means invalid/unavailable, 3 busy, 5 operation failure. `wait` performs reconciliation until converged or failure/timeout; it is not a guarantee against future writes.

`create ... --json` emits a machine inspection after creation. Errors/logs from shell setup go to stderr. `start`, `stop`, `restart`, `list`, `remove`, `ignore`, and `doctor` retain human CLI forms.

## Ignore and storage policy

`.foldersynkaignore` uses glob exclusions, not full gitignore semantics. Negation (`!`) is rejected. Git, `.mda`, secrets/environment files, dependency directories and designated generated outputs have protected defaults. Ignore policy is taken from the source side for both directions. Edit source ignore rules explicitly and review the next plan.

The beta synchronizes regular file content and nonempty directory trees. Empty directories, symlinks, ownership and timestamps are not mirrored. File/directory collisions require manual repair. POSIX executable mode is not transported; set executable bits explicitly in the private runtime when needed. Legacy `--compress`/`--checksum` are accepted for configuration compatibility; the content-hash reconciler always hashes and does not use compression. New profiles default to non-deleting copy. Legacy profiles without MODE derive copy/mirror from DELETE. Previously unsafe/unescaped shell configurations may be rejected; recreate profiles through the CLI while retaining source trees and old state for recovery.

## Development

See [agent instructions](AGENTS.md), [plan](docs/plan.md), [test commands](docs/TESTING.md), [dated reports](reports/README.md), and [progress](progress/README.md). Linux verification does not certify Android/proot/Acode behavior; [device acceptance](docs/DEVICE-ACCEPTANCE.md) remains mandatory.
