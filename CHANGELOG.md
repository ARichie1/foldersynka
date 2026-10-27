## 1.1.0-beta.1 — 2026-10-26

- Add content-hash copy/mirror/bidirectional reconciliation, JSON integration commands, conflict resolution and retained file bytes.
- Add a bulk-deletion hold, strict data parsing, canonical root validation, safer defaults and ownership-aware locks.
- Reconcile both roots periodically in the supervised foreground service.
- Add agent instructions, development roles, CI, dated reports/progress and offline safety/contract tests.
- Python 3 is now required. Empty directories, symlinks and metadata transport remain unsupported. Physical Android acceptance is pending.

# Changelog

All notable changes to FolderSynka are documented in this file.

The project follows Semantic Versioning.

---

## [1.0.0] - 2026-08-30

### Added

- Termux-focused FolderSynka CLI.
- Named synchronization profiles.
- Source and destination configuration.
- Rsync-based synchronization.
- Event-driven synchronization using `inotifywait`.
- Termux/runit service generation and lifecycle management.
- `.foldersynkaignore` support.
- Profile runtime state and synchronization health tracking.
- Centralized validation and error handling.
- Environment diagnostics through `doctor`.
- Installation and uninstallation scripts.
- Integration test suite covering the main application lifecycle.
- Documentation for installation, configuration, profiles, services, ignore
  rules, diagnostics, and testing.

### Changed

- Consolidated filesystem paths and profile configuration around canonical
  APIs.
- Consolidated logging, terminal output, filesystem utilities, argument
  parsing, and validation responsibilities.
- Reworked synchronization engine coordination between rsync, filesystem
  watching, services, and runtime state.
- Reworked Termux service generation to use canonical service paths and
  delegate execution to the synchronization engine.
- Corrected profile creation so runtime directories and ignore files are
  initialized correctly.
- Corrected synchronization option persistence for compression, checksum,
  and delete behavior.
- Corrected watcher process tracking and shutdown behavior.
- Updated documentation to match the final `1.0.0` command surface.

### Fixed

- Removed obsolete `fs_profile_file` and `fs_path_exists` references.
- Corrected inconsistent logger call signatures.
- Corrected the `.foldersynkaignore` template filename and documented path.
- Corrected ignore-file appending when the existing file has no trailing
  newline.
- Corrected service startup to invoke the engine directly.
- Corrected service validation so a service may be created during start.
- Corrected stop validation for profiles currently synchronizing.
- Corrected removal validation for active profiles.
- Corrected runtime initialization during first profile creation.
- Corrected the CLI router's command execution path.
- Corrected Termux shared-storage validation for supported storage layouts.
- Corrected uninstallation so generated FolderSynka services are stopped and
  removed.
- Added the canonical `fs_ignore_read` API.
- Corrected directory-pattern matching for ignore rules.
- Corrected unknown CLI commands to return a failure status.
- Corrected installation to initialize runtime directories before first use.
- Expanded integration coverage for invalid input, ignore lifecycle, and
  service restart.

### Verification

- All shell scripts pass `bash -n`.
- Installation and uninstallation were verified in a temporary Termux-like
  environment.
- Full integration lifecycle verification completed successfully:
  `31 passed, 0 failed`.
- Installation lifecycle verification completed successfully in a
  Termux-like environment.
- The final release boundary is intentionally limited to the existing
  FolderSynka feature set; no new application subsystem was added for the
  release.

---

## Unreleased

No changes currently planned for the `1.0.0` release boundary.
