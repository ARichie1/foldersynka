# Imported legacy working ledger

Imported on 2026-10-26. Original notes below are historical claims, not verification rerun at this checkpoint.



FolderSynka — Change Log Working Notes

«Status: Complete — v1.0.0 release candidate verified
Purpose: Internal record of corrections made during the pre-v1 cleanup.
Final: This file is the authoritative working ledger used to produce the official "CHANGELOG.md".»

---

Phase 1 — Foundation / Contracts

1. "core/config/paths.sh"

Changes

- Established canonical filesystem path names.
- Removed duplicated runtime path aliases.
- Consolidated runtime directories under "FS_RUNTIME_DIR".
- Standardized paths for:
  - configuration
  - state
  - logs
  - PIDs
  - locks
  - cache
  - services
- Standardized profile-specific path helper naming.
- Standardized profile configuration path generation.
- Standardized profile log path generation.
- Standardized profile PID path generation.
- Standardized profile lock path generation.
- Standardized profile runtime-state path generation.
- Standardized Termux service path generation.
- Standardized service-name generation.
- Standardized ".foldersynkaignore" filename handling.
- Removed path helpers that duplicated canonical constants.
- Ensured "paths.sh" remains responsible only for defining paths and path helpers.
- Prevented the paths layer from creating, deleting, or modifying filesystem objects.

Reason

The previous version contained overlapping path variables and helper names. This created ambiguity about which path was canonical and caused downstream modules to reference different names for the same resource.

---

2. "core/lib/constants.sh"

Changes

- Audited ownership of application-wide constants.
- Established "constants.sh" as the owner of global immutable constants.
- Identified constants that had been duplicated between "constants.sh" and configuration files.
- Moved/retained global profile constants in the constants layer.
- Moved/retained service-related constants in the constants layer.
- Established ownership for "FS_IGNORE_FILE".
- Established ownership for profile-name validation constants.
- Established ownership for service constants.
- Established ownership for other application-wide immutable values.

Reason

Global constants must have one owner. Duplicate ownership caused values to potentially diverge between modules.

---

3. "core/config/defaults.sh"

Changes

- Restricted "defaults.sh" to application/profile default values.
- Removed responsibility for global constants.
- Removed duplicate ownership of values belonging to "constants.sh".
- Kept configurable defaults such as:
  - watch behavior
  - deletion behavior
  - compression
  - checksum behavior
  - symlink behavior
  - automatic startup
  - logging level
  - debounce timing
  - retry delay
  - watcher events
  - rsync defaults
- Kept configuration-version defaults in the configuration layer where appropriate.

Reason

Defaults and constants have different responsibilities. Constants describe application contracts; defaults describe values that a newly-created profile starts with.

---

4. "core/config/config.sh"

Changes

- Kept "config.sh" as the public configuration entry point.
- Established configuration loading order.
- Ensured foundational path definitions are loaded before dependent configuration modules.
- Ensured defaults are available before profile configuration is constructed.
- Ensured runtime/profile/state modules are loaded after their dependencies.
- Removed unnecessary configuration logic from the public entry point.

Loading relationship

paths.sh
    ↓
constants.sh
    ↓
defaults.sh
    ↓
runtime.sh
    ↓
profile.sh
    ↓
state.sh

Reason

The configuration subsystem needs a deterministic dependency order so modules never attempt to use variables or functions that have not yet been defined.

---

5. "core/config/profile.sh"

Changes

- Established "profile.sh" as the canonical profile-management API.
- Standardized profile creation.
- Standardized profile loading.
- Standardized profile updating.
- Standardized profile deletion.
- Standardized profile listing.
- Standardized profile existence checks.
- Standardized profile property access.
- Aligned profile configuration paths with the canonical paths layer.
- Aligned profile defaults with "defaults.sh".
- Aligned service-name generation with the canonical service API.
- Aligned profile runtime values with the state layer.
- Removed responsibility for global constants from the profile layer.
- Preserved profile-specific configuration ownership within "profile.sh".

Reason

Profile management was spread across multiple layers. "profile.sh" needs to be the single source of truth for profile CRUD and profile configuration loading.

---

Phase 2 — Runtime / State

6. "core/config/runtime.sh"

Changes

- Restricted "runtime.sh" to runtime filesystem management.
- Standardized runtime initialization.
- Standardized runtime verification.
- Standardized runtime ensuring.
- Standardized runtime reset.
- Standardized cache clearing.
- Added the canonical state directory to runtime initialization/verification.
- Ensured runtime directories correspond to the canonical paths from "paths.sh".
- Removed responsibility for runtime state values from "runtime.sh".

Runtime directories

~/.foldersynka/
├── configs/
├── state/
├── logs/
├── pids/
├── locks/
├── cache/
└── services/

Reason

Runtime filesystem management and runtime state management were becoming mixed together. "runtime.sh" should manage the filesystem structure; "state.sh" should manage the contents/state represented inside that structure.

---

7. "core/config/state.sh"

Changes

- Established "state.sh" as the canonical runtime-state API.
- Standardized persistent state storage at:

~/.foldersynka/state/<profile>/runtime.conf

- Consolidated state loading.
- Consolidated state persistence.
- Removed duplicate persistence implementations.
- Kept "fs_state_commit()" as the canonical persistence operation.
- Retained "fs_state_save()" only as a compatibility alias.
- Standardized profile status management.
- Standardized PID management.
- Standardized lock management.
- Standardized service-state management.
- Standardized health-state management.
- Standardized error-state management.
- Standardized retry-state management.
- Standardized synchronization statistics.
- Standardized runtime-state validation.
- Standardized runtime-state snapshots.

Canonical PID API

fs_state_pid_write
fs_state_pid_read
fs_state_pid_exists
fs_state_pid_remove

Canonical lock API

fs_state_lock_acquire
fs_state_lock_release
fs_state_lock_exists

Canonical status API

fs_state_status
fs_state_mark_starting
fs_state_mark_running
fs_state_mark_syncing
fs_state_mark_stopping
fs_state_mark_stopped
fs_state_is_running
fs_state_is_stopped

Canonical service-state API

fs_state_service_write
fs_state_service_read

Lock API correction

The previous competing interface:

fs_state_lock
fs_state_unlock

was removed.

The canonical interface is now:

fs_state_lock_acquire
fs_state_lock_release
fs_state_lock_exists

Reason

The project previously had competing state APIs, particularly around locks. This created ambiguity between logical state and actual runtime resources. The state layer now exposes one consistent API for each runtime concern.

---

Cross-Phase Contract Changes

Path Ownership

paths.sh
    → filesystem locations

Constant Ownership

constants.sh
    → immutable application constants

Default Ownership

defaults.sh
    → default configuration values

Profile Ownership

profile.sh
    → profile CRUD and profile configuration

Runtime Ownership

runtime.sh
    → runtime filesystem lifecycle

State Ownership

state.sh
    → runtime state, PID, locks, status and service state

---

API Cleanup

The following principle is now being enforced:

«One responsibility → one canonical owner → one canonical API.»

Known areas corrected so far:

Paths       → paths.sh
Constants   → constants.sh
Defaults    → defaults.sh
Profiles    → profile.sh
Runtime     → runtime.sh
State       → state.sh
Locks       → state.sh
PIDs        → state.sh
Status      → state.sh

---

Remaining Work
This file will be extended after each phase.


Phase 3 — Utilities

8. "core/utils/logger.sh"

Changes

- Established "logger.sh" as the central logging utility.
- Standardized the public logger API.
- Removed the requirement to pass a profile name to every logging call.
- Standardized logging calls to:
  - "fs_log_debug"
  - "fs_log_info"
  - "fs_log_warn"
  - "fs_log_error"
  - "fs_log_success"
- Changed logger calls to accept the message as the primary argument.
- Made the logger determine the active profile internally when a profile is available.
- Added fallback logging to "FS_MAIN_LOG" for system-level messages.
- Standardized log-file resolution through the canonical paths API.
- Removed duplicated profile log-path construction from the logger.
- Standardized log levels, including "SUCCESS".
- Preserved timestamp generation in the logging layer.
- Kept terminal presentation separate from log-file persistence.
- Preserved log reading, clearing, existence, size, and rotation operations.
- Removed unnecessary dependency on caller-provided profile identifiers.

Reason

The previous logger API required callers to provide a profile explicitly, resulting in inconsistent calls such as "fs_log_info "$profile" "message"" and "fs_log_info "message"". The logger now exposes one public signature and resolves the active logging context internally.

---

9. "core/utils/filesystem.sh"

Changes

- Restricted "filesystem.sh" to filesystem and path operations.
- Removed the dependency on "logger.sh".
- Changed filesystem errors to use the terminal utility directly.
- Aligned filesystem operations with the canonical paths established in Phase 1.
- Standardized path existence checks around "fs_exists".
- Removed the obsolete "fs_path_exists" dependency.
- Preserved path expansion and normalization.
- Preserved protected-path detection.
- Preserved safe-path validation.
- Preserved file and directory creation operations.
- Preserved safe removal operations.
- Preserved copy and move operations.
- Preserved file-writing and append operations.
- Preserved atomic file writing.
- Preserved symbolic-link operations.
- Preserved permission helpers.
- Preserved temporary-file and temporary-directory helpers.
- Preserved filesystem metadata and checksum helpers.
- Preserved filesystem diagnostics.
- Removed unnecessary coupling between filesystem operations and application logging.

Reason

The filesystem layer previously depended on the logger even though filesystem operations are a lower-level utility. This created unnecessary dependency coupling and made the utility hierarchy harder to reason about.

---

10. "core/utils/terminal.sh"

Changes

- Established "terminal.sh" as the terminal presentation and interaction layer.
- Preserved colored status output.
- Standardized success, error, warning, and informational output helpers.
- Preserved plain-text output.
- Preserved headers, sections, dividers, key-value output, and list formatting.
- Preserved interactive prompts.
- Preserved confirmation handling.
- Preserved fatal-error handling.
- Preserved the FolderSynka terminal banner.
- Kept terminal presentation independent from logging and filesystem operations.

Reason

Terminal output is a presentation concern and should remain independent from higher-level logging and filesystem logic.

---

11. "core/utils/validation.sh"

Changes

- Restricted "validation.sh" to reusable validation primitives.
- Aligned profile configuration lookup with the canonical "fs_profile_config_file" API from Phase 1.
- Removed the obsolete "fs_profile_file" dependency.
- Aligned filesystem existence checks with the canonical "fs_exists" API.
- Removed the obsolete "fs_path_exists" dependency.
- Aligned ignore-file validation with the canonical "FS_IGNORE_FILE" constant.
- Expanded runtime validation to include the canonical runtime directories established in Phases 1 and 2.
- Preserved profile-name validation.
- Preserved profile existence and missing-profile validation.
- Preserved profile configuration validation.
- Preserved source and destination validation.
- Preserved optional ignore-file validation.
- Preserved Termux service validation.
- Preserved dependency validation.
- Preserved storage validation.
- Preserved execution-environment validation.
- Preserved composite environment and system validation.
- Removed unnecessary duplication of path and profile contracts.

Reason

The validation layer contained references to APIs that had been replaced during the Phase 1 foundation cleanup. Validation must consume the canonical APIs rather than maintain alternative versions of those contracts.

---

12. "core/utils/arguments.sh"

Changes

- Established "arguments.sh" as the command-line argument parsing layer.
- Standardized argument storage using the "FS_ARGS" associative array.
- Preserved argument reset, set, get, and existence operations.
- Standardized required-option-value validation.
- Standardized unknown-option reporting.
- Preserved create-command argument parsing.
- Preserved support for positional profile names.
- Preserved source and destination options.
- Preserved compression and checksum flags.
- Preserved delete-control flags.
- Preserved interval and watch options.
- Preserved help handling.
- Removed direct process termination from reusable argument-validation helpers.
- Changed parser errors to return failure so calling commands can handle them.
- Kept application configuration ownership outside the argument parser.

Reason

The argument parser should parse and report invalid input without taking ownership of command execution or application configuration. Returning failure makes the parser reusable while keeping command behavior in the command layer.

---

Phase 3 — Cross-Utility Contract

The following utility ownership is now enforced:

Terminal
→ terminal output and interaction

Logger
→ application logging

Filesystem
→ filesystem operations and path handling

Validation
→ reusable validation primitives

Arguments
→ command-line argument parsing

The dependency direction is kept deliberately simple:

paths
↓
terminal
↓
filesystem

paths
↓
logger
↓
terminal

config
↓
validation
↓
filesystem

---

Phase 3 — API Cleanup

The following principles are now being enforced:

"One responsibility → one canonical owner → one canonical API."

Known utility contracts corrected:

Logging       → logger.sh
Terminal      → terminal.sh
Filesystem    → filesystem.sh
Validation    → validation.sh
Arguments     → arguments.sh

Logger API:

fs_log_debug "message"
fs_log_info "message"
fs_log_warn "message"
fs_log_error "message"
fs_log_success "message"

Filesystem existence API:

fs_exists "path"

Profile configuration API:

fs_profile_config_file "profile"

Ignore-file ownership:

FS_IGNORE_FILE

---

Phase 3 — Verification Required

Before Phase 3 is considered fully closed:

1. Search the entire project for old logger signatures.
2. Update callers still passing profile names to logger functions.
3. Search for remaining uses of "fs_profile_file".
4. Search for remaining uses of "fs_path_exists".
5. Search for duplicate "FS_IGNORE_FILE" definitions.
6. Run shell syntax checks on all modified files.
7. Test profile logging.
8. Test system-level logging.
9. Test filesystem validation.
10. Test argument parsing.
11. Verify no utility introduces a circular dependency.

Phase 3 is considered structurally corrected, but the phase should only be marked complete after the project-wide caller audit and verification are finished.


Phase 4 — Validation

8. "core/validation/pipeline.sh"

Changes

- Established "pipeline.sh" as the shared validation-pipeline dispatcher.
- Standardized validation pipeline execution through "fs_run_validation_pipeline()".
- Standardized individual validation execution through "fs_pipeline_step()".
- Added validation-function existence checking before pipeline execution.
- Standardized pipeline success handling through "fs_pipeline_success()".
- Preserved pipeline failure handling through "fs_pipeline_failure()".
- Removed unnecessary duplicated pipeline logic.
- Ensured command-specific validation remains under "core/validation/".
- Kept primitive validation responsibility within "core/utils/validation.sh".

Reason

Validation orchestration and primitive validation were previously mixed together. The pipeline layer now dispatches and executes command-specific validation without becoming another source of validation rules.

---

9. "core/validation/create.sh"

Changes

- Standardized the profile-creation validation pipeline.
- Added environment validation.
- Added canonical profile-name validation.
- Added canonical profile-existence validation.
- Added source-directory validation.
- Added destination validation.
- Added ignore-file validation.
- Removed duplicated validation logic from the create pipeline.
- Ensured the create pipeline uses primitive validators from "core/utils/validation.sh".
- Kept profile creation itself outside the validation layer.

Reason

The create pipeline should validate whether a profile can safely be created without performing the creation operation itself.

---

10. "core/validation/start.sh"

Changes

- Standardized the start validation pipeline.
- Added environment validation.
- Added canonical profile-name validation.
- Added profile-existence validation.
- Added runtime validation.
- Added Termux Services validation.
- Added generated-service existence validation.
- Standardized profile configuration loading through "profile.sh".
- Added source validation using the loaded profile configuration.
- Added destination validation using the loaded profile configuration.
- Added ignore-file validation.
- Added running-state validation through the canonical state API.
- Removed references to non-canonical validation functions.
- Removed duplicate dependency validation logic.

Reason

Starting a profile requires validation of the environment, profile, runtime, service, filesystem and current runtime state. These checks now use the canonical APIs established in Phases 1–3.

---

11. "core/validation/stop.sh"

Changes

- Established the stop validation pipeline.
- Added environment validation.
- Added profile-name validation.
- Added profile-existence validation.
- Added runtime validation.
- Added Termux Services validation.
- Added generated-service existence validation.
- Added canonical running-state validation.
- Prevented stop operations against profiles that are not currently running.
- Kept service stopping outside the validation layer.

Reason

The stop pipeline should verify that a valid, running profile exists before the command performs the actual stop operation.

---

12. "core/validation/remove.sh"

Changes

- Established the remove validation pipeline.
- Added environment validation.
- Added profile-name validation.
- Added profile-existence validation.
- Added runtime validation.
- Added running-state validation.
- Prevented removal of an actively running profile.
- Kept profile deletion outside the validation layer.
- Reused canonical profile and state APIs.

Reason

Profile removal must be blocked while the profile is running. The validation layer now performs this safety check without performing the removal itself.

---

13. "core/validation/doctor.sh"

Changes

- Established the system-diagnostic validation pipeline.
- Added Termux environment validation.
- Added HOME validation.
- Added PREFIX validation.
- Added PATH environment validation.
- Added temporary-directory validation.
- Added shared-storage validation.
- Added storage-permission validation.
- Added rsync dependency validation.
- Added inotify dependency validation.
- Added runit/service-manager validation.
- Added Termux Services validation.
- Added FolderSynka runtime validation.
- Removed dependency on profile-specific validation.
- Kept doctor validation focused on system and runtime readiness.

Reason

The doctor pipeline is intended to validate the environment required for FolderSynka to operate rather than validate an individual profile.

---

14. "core/validation/sync.sh"

Changes

- Established the sync validation pipeline.
- Added environment validation.
- Added profile-name validation.
- Added profile-existence validation.
- Added runtime validation.
- Standardized profile configuration loading through "profile.sh".
- Added source-directory validation.
- Added destination validation.
- Added ignore-file validation.
- Added rsync dependency validation.
- Removed service lifecycle checks from sync validation.
- Kept synchronization itself outside the validation layer.

Reason

Synchronization requires a valid profile, usable source and destination paths, a valid ignore configuration and the required synchronization dependency. Service lifecycle concerns belong to the start/stop pipelines instead.

---

Phase 4 — Cross-Layer Validation Changes

Validation Ownership

"core/utils/validation.sh"
→ primitive validators

"core/validation/pipeline.sh"
→ validation dispatch and pipeline execution

"core/validation/create.sh"
→ create validation

"core/validation/start.sh"
→ start validation

"core/validation/stop.sh"
→ stop validation

"core/validation/remove.sh"
→ remove validation

"core/validation/doctor.sh"
→ system diagnostics

"core/validation/sync.sh"
→ synchronization validation

---

Validation API Cleanup

- Removed references to non-canonical composite validators.
- Removed duplicate primitive validation implementations from command-specific pipelines.
- Standardized pipelines to call reusable primitive validators.
- Ensured validation pipelines do not perform the operations they validate.
- Ensured profile operations continue to use "profile.sh".
- Ensured runtime filesystem operations continue to use "runtime.sh".
- Ensured runtime state operations continue to use "state.sh".
- Ensured filesystem checks continue to use "filesystem.sh".
- Ensured logging continues to use the Phase 3 canonical logger API.
- Preserved the principle:

"One responsibility → one canonical owner → one canonical API."

---

Phase 4 Contract

Primitive validation
↓
core/utils/validation.sh

Command validation
↓
core/validation/*.sh

Validation dispatch
↓
core/validation/pipeline.sh

Command execution
↓
core/commands/*

The validation layer validates operations but does not execute them.

---

Reason

The previous validation structure contained duplicated checks, references to obsolete APIs and unclear boundaries between primitive validators and command-specific validation.

Phase 4 establishes a clean validation hierarchy in which reusable validation primitives live in "core/utils/validation.sh", command-specific validation lives in "core/validation/", and command execution remains the responsibility of "core/commands/".



Phase 5 — Engine
Scope
Reworked the FolderSynka synchronization engine to align with the corrected architecture established in Phases 1–4.
Files Updated
core/engine/rsync.sh
core/engine/watcher.sh
core/engine/sync-engine.sh
Changes
core/engine/rsync.sh
Reworked rsync abstraction around the canonical profile API.
Replaced legacy profile variables:
FS_PROFILE_SRC → FS_PROFILE_SOURCE
FS_PROFILE_DEST → FS_PROFILE_DESTINATION
Added explicit profile-aware logging.
Centralized rsync command construction.
Added support for:
Archive mode
Compression
Checksum comparison
Delete synchronization
Symbolic-link following
Profile ignore files
Added normal synchronization and dry-run operations.
Added profile-level synchronization helpers.
Reused Phase 4 primitive validation instead of duplicating validation logic.
Added rsync availability and version handling.
core/engine/watcher.sh
Reworked filesystem watching around the canonical profile API.
Centralized inotifywait command construction.
Added filesystem event normalization:
CREATED
UPDATED
DELETED
MOVED
UNKNOWN
Added filtering for temporary/editor files and configured ignore files.
Added debounce handling.
Added watcher lifecycle management:
Start
Stop
Restart
Status
Added watcher PID tracking.
Kept synchronization logic outside the watcher.
Added profile-aware logging.
Removed reliance on obsolete Phase 1–3 APIs.
core/engine/sync-engine.sh
Reworked the synchronization engine as the coordinator between:
Profile configuration
Rsync
Filesystem watcher
Runtime state
Added canonical synchronization flow.
Added initial synchronization before watcher startup.
Added synchronization locking to prevent concurrent sync operations.
Added state transitions:
starting
syncing
running
stopping
stopped
Added synchronization error persistence.
Added retry tracking.
Added synchronization timestamp updates.
Added health state updates.
Added watcher PID persistence through the state API.
Added clean engine start, stop, restart, and status operations.
Added engine information reporting.
Removed direct manipulation of runtime state files.
Reused the Phase 4 validation layer.
Removed stale profile variable references.
Updated logging to use the corrected Phase 3 logger API.
Architectural Result
Phase 5 establishes the following engine flow:
Plain text
Profile Configuration
        │
        ▼
  Validation Layer
        │
        ▼
  Synchronization
      Engine
      /    \
     ▼      ▼
  Rsync   Watcher
     │      │
     └──┬───┘
        ▼
 Runtime State
The engine now consumes the canonical APIs established by the previous phases rather than maintaining duplicate configuration, validation, logging, or state mechanisms.
Phase 5 Status
Engine layer rewritten and aligned with Phases 1–4.
Files completed:
core/engine/rsync.sh
core/engine/watcher.sh
core/engine/sync-engine.sh
Next: Test the complete Phase 5 engine before beginning Phase 6.


# Phase 6 — Service System

## Objective

Refactor the FolderSynka service system so service management follows the architecture established in Phases 1–5.

The service layer must be responsible only for managing the Termux/runit service lifecycle. It must rely on the canonical configuration, path, validation, state, and engine APIs rather than duplicating logic.

## Files

Fix:

- `core/services/service-generator.sh`

## Changes

### 1. Remove Duplicate Service Naming

Remove the local `fs_service_name()` implementation from:

`core/services/service-generator.sh`

Service names are now provided by the canonical path API:

```bash
fs_service_name "$profile"

from:
core/config/paths.sh
Do not recreate service names using hard-coded strings such as:
Bash
foldersynka-${profile}
2. Use Canonical Service Paths
Use:
Bash
fs_service_directory "$profile"
or the canonical service path API from core/config/paths.sh.
Do not duplicate Termux service path construction inside the service layer.
3. Service Creation
fs_service_create() must:
Validate the profile.
Ensure the profile exists.
Load the profile when required.
Create the service directory.
Generate the run script.
Make the run script executable.
Use the canonical executable name.
Avoid duplicating engine logic.
The generated service must delegate execution to the engine rather than performing synchronization itself.
4. Service Removal
fs_service_remove() must:
Stop the service if necessary.
Remove the generated service directory.
Leave profile configuration untouched.
Leave unrelated profiles untouched.
Use canonical service paths.
5. Service Start
fs_service_start() must:
Validate the environment.
Validate the profile.
Ensure the service exists or create it.
Start the canonical Termux/runit service.
Return failure when the service cannot be started.
6. Service Stop
fs_service_stop() must:
Safely handle a missing service.
Stop an existing service.
Return an appropriate failure when stopping fails.
Avoid manipulating runtime state directly unless that responsibility belongs to the state/engine layer.
7. Service Restart
fs_service_restart() must:
Stop the existing service.
Start it again.
Propagate failures.
Avoid duplicating service lifecycle logic.
8. Service Status
fs_service_status() must use the canonical service name and report the actual runit service state.
9. Service Listing
fs_service_list() must:
Inspect the canonical Termux service directory.
List only FolderSynka-generated services.
Avoid hard-coded alternate service locations.
10. Validation Responsibility
Do not duplicate primitive validation functions inside the service layer.
Use the validation APIs established in Phase 4.
Examples:
Bash
fs_validate_environment
fs_validate_dependencies
fs_validate_profile_name
fs_validate_profile_exists
fs_validate_termux_services
Service-specific validation should remain in the validation pipeline where appropriate.
11. Error Handling
Use the centralized error system established in Phases 1–4.
Do not introduce new ad-hoc error handling or duplicate error registries.
Service failures should use the existing service error codes where applicable:
Plain text
FS_ERR_SERVICE_NOT_FOUND
FS_ERR_SERVICE_ALREADY_EXISTS
FS_ERR_SERVICE_START_FAILED
FS_ERR_SERVICE_STOP_FAILED
FS_ERR_SERVICE_RESTART_FAILED
12. Logging
Use the centralized logger.
Examples:
Bash
fs_log_debug
fs_log_info
fs_log_warning
fs_log_error
Do not use scattered echo statements for operational logging.
Architectural Rules
The service system must follow this dependency direction:
Plain text
CLI
 │
 ▼
Service Commands
 │
 ▼
Service System
 │
 ├── Config
 ├── Paths
 ├── Validation
 └── Engine
The service layer must not become another location for:
profile management
validation primitives
runtime state management
synchronization logic
watcher logic
rsync command construction
Those responsibilities belong to their respective modules.
Expected Result
After Phase 6:
Service naming has one canonical implementation.
Service paths have one canonical implementation.
Termux/runit lifecycle is isolated in the service layer.
Services execute the synchronization engine.
Service commands use centralized validation.
Service errors use the centralized error system.
Service operations use centralized logging.
No duplicate service-management primitives remain.



Phase 7 — Libraries
Objective
Audit and refactor the shared library layer so it provides the canonical low-level APIs used by the rest of FolderSynka.
The library layer must contain reusable primitives and contracts only.
Higher-level behavior must remain in:
core/config
core/validation
core/engine
core/services
command modules
Files
Audit and fix:
core/lib/constants.sh
core/lib/environment.sh
core/lib/error-codes.sh
core/lib/error-registry.sh
core/lib/errors.sh
core/lib/exit-codes.sh
core/lib/process.sh
core/lib/strings.sh
core/lib/validation-context.sh
Note: the old filename core/lib/enviroment.sh must be corrected to core/lib/environment.sh.
Changes
1. Constants
core/lib/constants.sh must remain the single source of truth for immutable application constants.
It must define:
Application identity.
Executable name.
Profile configuration extension.
Runtime file name.
Ignore file name.
Profile naming rules.
Service prefix.
Logging formats.
Runtime status values.
Health values.
Boolean values.
Remove duplicate declarations.
Use one declaration per constant.
2. Environment
core/lib/environment.sh must provide environment inspection only.
Responsibilities include:
Termux detection.
OS detection.
Architecture detection.
Storage availability.
Command existence checks.
Environment-variable checks.
Basic runtime information.
It must not:
Modify configuration.
Create application directories.
Start services.
Run synchronization.
Perform validation pipelines.
3. Error Codes
core/lib/error-codes.sh must be the canonical registry of symbolic application error identifiers.
Remove duplicate error-code declarations.
Every symbolic error code should be defined once.
Error codes must remain independent from:
human-readable messages
logging
exit behaviour
4. Exit Codes
core/lib/exit-codes.sh must remain the canonical process-exit-code registry.
Maintain semantic groups for:
POSIX/general failures.
Generic application errors.
Profile errors.
Filesystem errors.
Runtime errors.
Service errors.
Dependency errors.
Engine errors.
Validation errors.
Internal errors.
Do not duplicate exit-code definitions elsewhere.
5. Error Registry
core/lib/error-registry.sh must map:
Plain text
error code
    ↓
exit code
severity
message
hint
Remove duplicate registrations.
An error code must not be registered multiple times with conflicting metadata.
The registry must use the canonical error and exit-code definitions.
6. Error API
core/lib/errors.sh must provide the canonical error lifecycle:
Plain text
reset
set
lookup
inspect
print
exit
The fs_fail() helper must use the centralized registry instead of constructing errors locally.
Errors should therefore flow through:
Plain text
Error Code
    ↓
Error Registry
    ↓
Error Context
    ↓
Formatted Output
    ↓
Exit Code
7. Process API
core/lib/process.sh must provide reusable process primitives only.
Maintain APIs for:
Current PID.
Process existence.
Sending signals.
Normal termination.
Forced termination.
Background execution.
Waiting.
Basic lock-file primitives.
Do not duplicate runtime state locking implemented by:
core/config/state.sh
The library process lock helpers must remain generic.
8. Strings API
core/lib/strings.sh must contain generic string operations only.
Maintain:
lowercase conversion
uppercase conversion
trimming
empty checks
prefix checks
suffix checks
contains checks
repetition
slug generation
No application-specific validation should be moved into this file.
9. Validation Context
core/lib/validation-context.sh must remain the shared validation result/context API.
It must provide:
Bash
fs_validation_reset
fs_validation_success
fs_validation_fail
fs_validation_ok
fs_validation_code
fs_validation_message
fs_validation_field
fs_validation_require
It must integrate with the centralized error API.
Validation context must not contain individual filesystem/profile/service validation rules.
Those belong to the validation layer established in Phase 4.
10. Dependency Direction
The library layer must remain at the bottom of the architecture.
Plain text
Application
    │
    ├── Commands
    ├── Services
    ├── Engine
    ├── Validation
    └── Config
             │
             ▼
           Libs
Libraries must not depend on higher-level application modules.
In particular, libraries must not depend on:
commands
services
engine
validation pipelines
profile management
synchronization logic
11. Duplicate Removal
Remove duplicate implementations introduced during earlier iterations.
Examples include:
duplicate error codes
duplicate exit codes
duplicate validation state
duplicate environment helpers
duplicate service naming
duplicate runtime primitives
Every shared primitive should have one canonical owner.
12. Service Naming Consistency
The canonical service-name API is:
Bash
fs_service_name() {
    local profile="$1"

    printf '%s-%s\n' \
        "$FS_SERVICE_PREFIX" \
        "$profile"
}
It belongs in:
core/config/paths.sh
Do not move this implementation into the libraries.
All service-related modules must consume this API rather than recreate service names.
Expected Result
After Phase 7:
The library layer contains clean reusable primitives.
Constants have one canonical definition.
Error codes have one canonical definition.
Exit codes have one canonical definition.
Error metadata has one canonical registry.
Validation context is centralized.
Environment detection is isolated.
Process helpers are generic.
String helpers are generic.
No higher-level application logic leaks into core/lib.
No duplicate primitive implementations remain.
Service naming remains centralized in core/config/paths.sh.
Phase Completion Criteria
Phase 7 is complete when:
Plain text
core/lib/
├── constants.sh
├── environment.sh
├── error-codes.sh
├── error-registry.sh
├── errors.sh
├── exit-codes.sh
├── process.sh
├── strings.sh
└── validation-context.sh
are internally consistent and all higher-level modules can consume their APIs without redefining them.
The resulting architecture should have a clear separation:
Plain text
constants
    ↓
paths / config
    ↓
libraries
    ↓
validation
    ↓
engine
    ↓
services
    ↓
commands
Each layer owns its responsibility and consumes the canonical APIs provided by the layers beneath it.


## Phase 8 — CLI Commands & Ignore API

### Status

Completed

### Objective

Complete the FolderSynka CLI command layer and introduce a dedicated
`.foldersynkaignore` management API while maintaining the architectural
separation established in Phases 1–7.

### Completed Work

#### 1. Ignore API

Added:

`core/config/ignore.sh`

Implemented the canonical Ignore API responsible for:

- Resolving profile ignore files
- Checking ignore-file existence
- Creating ignore files from the canonical template
- Initializing missing ignore files
- Validating ignore files
- Normalizing ignore patterns
- Validating ignore patterns
- Listing ignore patterns
- Checking whether a pattern exists
- Adding ignore patterns
- Removing ignore patterns
- Testing paths against ignore patterns
- Printing ignore files
- Resetting ignore files to the canonical template
- Reporting ignore-file information

The Ignore API is now the single ownership layer for
`.foldersynkaignore` operations.

#### 2. Ignore CLI

Rebuilt:

`core/cli/commands/ignore.sh`

The command now acts as a thin CLI layer over the Ignore API.

Supported operations:

- `init`
- `list`
- `show`
- `add`
- `remove`
- `reset`
- `info`

Example usage:

    foldersynka ignore <profile> init
    foldersynka ignore <profile> list
    foldersynka ignore <profile> show
    foldersynka ignore <profile> add "node_modules/"
    foldersynka ignore <profile> remove "node_modules/"
    foldersynka ignore <profile> reset
    foldersynka ignore <profile> info

The CLI is responsible for:

- Argument handling
- Profile resolution
- User-facing messages
- Command dispatch

The Ignore API remains responsible for actual ignore-file operations.

#### 3. Create Command Integration

Updated:

`core/cli/commands/create.sh`

Removed direct `.foldersynkaignore` template management from the
create command.

The command now depends on:

    core/config/ignore.sh

and initializes the ignore file through:

    fs_ignore_init

This removes duplicated ignore-file logic from the CLI.

The create flow is now:

    Parse Arguments
        ↓
    Validation Pipeline
        ↓
    Create Destination
        ↓
    Create Profile
        ↓
    Initialize Ignore File
        ↓
    Optional Service Start

#### 4. CLI Architecture

The CLI command layer now follows the established separation of
responsibilities:

    CLI Command
        ↓
    Validation / Configuration API
        ↓
    Core Logic
        ↓
    Filesystem / Runtime

Commands orchestrate operations rather than directly implementing
configuration-management logic.

#### 5. Error Integration

Ignore-file failures use the existing centralized error system:

    core/lib/error-codes.sh
    core/lib/error-registry.sh
    core/lib/errors.sh
    core/lib/validation-context.sh

Relevant ignore errors include:

    FS_ERR_IGNORE_FILE_NOT_FOUND
    FS_ERR_IGNORE_FILE_INVALID
    FS_ERR_IGNORE_FILE_NOT_READABLE

No separate CLI-specific error system was introduced.

### Architectural Improvements

Phase 8 establishes `.foldersynkaignore` as a first-class
FolderSynka configuration resource.

Before:

    create.sh
        ↓
    directly copies template

After:

    create.sh
        ↓
    ignore.sh API
        ↓
    canonical ignore management

This prevents duplicated ignore-file logic and gives future components
a reusable Ignore API.

### Files Added

    core/config/ignore.sh

### Files Updated

    core/cli/commands/create.sh
    core/cli/commands/ignore.sh

### Validation

The following operations should be verified:

    foldersynka ignore --help

    foldersynka ignore <profile> info

    foldersynka ignore <profile> init

    foldersynka ignore <profile> list

    foldersynka ignore <profile> show

    foldersynka ignore <profile> add "*.bak"

    foldersynka ignore <profile> list

    foldersynka ignore <profile> remove "*.bak"

    foldersynka ignore <profile> reset

    foldersynka create <profile> \
        --src <source> \
        --dest <destination>

### Phase Result

Phase 8 establishes a reusable Ignore API and a clean CLI boundary
for `.foldersynkaignore` management.

The CLI no longer owns ignore-file implementation details.

FolderSynka now has a dedicated configuration API for ignore
management that can be consumed by the CLI and, later, by the sync
engine without duplicating filesystem logic.



## Phase 9 — Installation

### Status
Completed

### Objective
Establish a proper installation and removal system for FolderSynka after the application is functional from the repository.

### Changes
/bin/foldersynka

Rebuilt the main executable as the installed CLI entry point.

### Defines and exports:
FS_HOME
FS_RUNTIME

Resolves the installed CLI router through FS_HOME.
Verifies that the installation is present before execution.

Ensures the router is executable.
Delegates all CLI arguments to core/cli/router.sh.
Keeps the executable as a thin entry-point layer with no application logic.
install.sh
Added the repository installation script.
Installs FolderSynka into the Termux prefix:
$PREFIX/bin/foldersynka
$PREFIX/share/foldersynka/
Copies the application source tree into the installation directory.
Installs the executable entry point.
Applies executable permissions to required shell scripts.
Creates the required runtime base directory where appropriate.
Validates the installation after copying.
Keeps repository files separate from the installed application.
uninstall.sh
Added the FolderSynka removal script.
Removes the installed executable.
Removes the installed application directory.
Does not blindly remove the user's runtime data under:
$HOME/.foldersynka
Provides clear feedback about what was removed.

### Installation Layout
Plain text
$PREFIX/
├── bin/
│   └── foldersynka
│
└── share/
    └── foldersynka/
        ├── VERSION
        └── core/
            ├── cli/
            ├── config/
            ├── lib/
            ├── services/
            ├── templates/
            ├── utils/
            └── validation/

### Runtime Separation
Installation files remain under:

$PREFIX/share/foldersynka/
User/runtime state remains under:

$HOME/.foldersynka/

This preserves the architectural separation established in earlier phases between application code and user-generated runtime data.
Permissions
The installation guarantees that:
bin/foldersynka is executable.
CLI scripts required through the router are executable.
Service scripts generated at runtime receive executable permissions.
Configuration and template files remain regular readable files.
Verification
The installation phase should verify at minimum:
Plain text
foldersynka
foldersynka --version
foldersynka --help
foldersynka doctor
A successful installation therefore means the application can be invoked through:
Bash
foldersynka
without requiring execution directly from the repository.
Architectural Consistency
Phase 9 preserves the boundaries established in Phases 1–8:
Config owns configuration.
Paths owns filesystem path construction.
Libs provide shared application APIs.
Validation handles validation pipelines.
Services handle service lifecycle.
CLI handles user-facing commands and routing.
Installation only installs/removes the application and does not duplicate application logic.
Result
FolderSynka now has a defined transition from:
Plain text
Repository
    ↓
install.sh
    ↓
$PREFIX/share/foldersynka/
    ↓
$PREFIX/bin/foldersynka
    ↓
core/cli/router.sh
and can be installed and removed as a proper Termux application rather than being executed directly from the development repository.




Final Changelog Preparation

After all correction phases are complete:

1. Review this file.
2. Remove internal debugging/correction language.
3. Group changes by user-visible impact.
4. Separate fixes from structural refactoring.
5. Add the final version number.
6. Add release date.
7. Convert this working document into the official "CHANGELOG.md".

This file is intentionally not the final changelog.
It is the technical ledger used to construct it.


---

# Phase 11 — Tests & Full Application Verification

## Objective

Exercise the complete FolderSynka lifecycle before release.

## Added

- Added `tests/test.sh` as the integration test suite.
- Added temporary test environments for runtime, profiles, source/destination
  workspaces, and Termux service simulation.

## Verified

- Version and help commands.
- Profile creation.
- Profile listing.
- Profile status.
- Profile configuration persistence.
- Compression/checksum/delete configuration flags.
- `.foldersynkaignore` initialization.
- Ignore rule addition and listing.
- Environment diagnostics.
- Initial synchronization.
- Event-driven synchronization through `inotifywait`.
- Service creation.
- Service start.
- Service status.
- Service stop.
- Profile removal.
- Installation and uninstallation flow.

## Result

The complete application lifecycle was exercised successfully.

Final integration test result:

`20 passed, 0 failed`

---

# Phase 12 — Documentation / CHANGELOG

## Changes

- Corrected documentation to match the final command surface.
- Removed the undocumented/unfinished `--interval` command option.
- Corrected the documented `.foldersynkaignore` template path.
- Added the repository integration-testing instructions.
- Corrected the release version in the official changelog from the stale
  `1.0.0` release version.
- Rebuilt `CHANGELOG.md` from the completed working notes.

---

# Phase 13 — Cleanup & Release Candidate

## Status

Complete — v1.0.0 release candidate verified.

## Final cleanup

- Removed accidental junk text from `install.sh`.
- Made `tests/test.sh` executable (`755`).
- Verified all shell files with `bash -n`.
- Corrected unknown CLI commands to return a non-zero exit status.
- Added the canonical `fs_ignore_read` API.
- Corrected directory-pattern matching in `fs_ignore_is_ignored`.
- Expanded integration coverage for invalid CLI input, ignore lifecycle operations, and service restart.
- Corrected installation to initialize the complete runtime directory structure.
- Updated release version references to `1.0.0`.

## Final verification

- Integration test suite: **31 passed, 0 failed**.
- Installation lifecycle: **passed** in a Termux-like test environment.
- Shell syntax validation: **passed** for all shell files.
- Test runner permissions: `tests/test.sh` is executable.

# Phase 14 — Public Publishing / v1.0.0 Release

## Status

Release package prepared.

## Release boundary

- Release version: `1.0.0`.
- No additional application features added.
- `VERSION` is `1.0.0`.
- `CHANGELOG.md` documents the completed release.
- `README.md` reflects the final command surface and workflow.
- Release candidate archive generated for user testing.

## Standard Git commit message

`chore(release): v1.0.0`

## User testing

The project is ready for final black-box testing from the user's Termux environment before pushing the release to the public GitHub repository.
