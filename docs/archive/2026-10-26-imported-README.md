# Historical README (imported 2026-10-26)

Superseded by the current root README. Historical commands and readiness claims below are not current acceptance evidence.


# FolderSynka

Developer-first workspace synchronization manager for Termux.

## Overview

FolderSynka is a lightweight directory synchronization tool designed for
Android development environments running through Termux.

It keeps a source workspace and a destination workspace synchronized using
native filesystem and synchronization utilities such as `rsync` and
`inotifywait`.

FolderSynka is designed around profiles, allowing each synchronization pair
to maintain its own configuration, runtime state, ignore rules, and service.

The project is built as a modular Bash application with a command-line
interface and a focus on predictable behavior, transparent configuration,
and developer-friendly workflows.

### Why FolderSynka?

Working with development projects on Android can involve multiple storage
locations, especially when source files are stored in shared Android storage
while development tools operate inside the Termux filesystem.

FolderSynka provides a controlled way to synchronize those workspaces without
requiring developers to manually copy files between locations.

A typical setup looks like this:

    Android Shared Storage
            │
            │
            ▼
       Source Workspace
            │
            │ FolderSynka
            │
            ▼
       Termux Workspace
            │
            ▼
       Development Tools

Each synchronization relationship is represented by a named profile.

Example:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project

The profile can then be controlled through the FolderSynka CLI:

    foldersynka start my-project
    foldersynka status my-project
    foldersynka stop my-project

   
## Features

- Profile-based synchronization
- One-way source-to-destination synchronization
- Continuous file watching with `inotifywait`
- Synchronization powered by `rsync`
- Configurable synchronization profiles
- Per-profile source and destination paths
- Per-profile runtime and state management
- `.foldersynkaignore` support
- Ignore-file management through the CLI
- Optional rsync compression
- Optional checksum-based comparison
- Optional deletion control
- Termux service integration
- Start, stop, restart, and status management
- Installation diagnostics with `doctor`
- Centralized validation pipeline
- Structured error and exit-code handling
- Shell-based CLI designed for Termux
- Lightweight installation with no external application runtime
- Repository-friendly configuration and development workflow

## Requirements

FolderSynka is designed for Android devices running Termux.

### Required

- Termux
- Bash
- `rsync`
- `inotify-tools`
- `termux-services`

### Recommended

- Termux:API
- Git
- Android shared-storage access

### Termux Packages

The required packages can be installed with:

    pkg update

    pkg install rsync inotify-tools termux-services

If Termux:API functionality is required, install the Termux:API package and
the corresponding Android application.

### Storage Access

FolderSynka may synchronize files between the Termux filesystem and Android
shared storage.

To enable shared-storage access, run:

    termux-setup-storage

After granting permission, Termux normally exposes Android shared storage
through:

    ~/storage/

FolderSynka does not require Android root access.

## Installation

FolderSynka can be installed directly from the project repository.

### Clone the Repository

Clone the project and enter the repository:

    git clone https://github.com/ARichie1/foldersynka.git

    cd foldersynka

Replace `<repository-url>` with the URL of your FolderSynka repository.

### Run the Installer

Make the installer executable:

    chmod +x install.sh

Run the installer:

    ./install.sh

The installer installs FolderSynka into the Termux prefix:

    $PREFIX/bin/foldersynka

and the application files into:

    $PREFIX/share/foldersynka/

After installation, verify the CLI:

    foldersynka --help

You can also check the installed version:

    foldersynka --version

### Installation Layout

The installation uses the following structure:

    $PREFIX/
    ├── bin/
    │   └── foldersynka
    │
    └── share/
        └── foldersynka/
            ├── VERSION
            ├── core/
            └── ...

Runtime data is kept separately from the installed application:

    $HOME/.foldersynka/

This separation allows the application to be upgraded or removed without
mixing application files with profile configuration and runtime state.

### Uninstallation

From the project repository, run:

    ./uninstall.sh

The uninstaller removes the installed FolderSynka application from the
Termux prefix.

User runtime data is handled separately from the application installation.


## Quick Start

Once FolderSynka is installed, create a synchronization profile by providing
a profile name, source directory, and destination directory.

### 1. Create a Profile

For example:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project

FolderSynka creates the profile configuration and initializes a
`.foldersynkaignore` file in the source directory when one does not already
exist.

### 2. Start Synchronization

Start the profile:

    foldersynka start my-project

FolderSynka performs the configured synchronization and starts watching the
source workspace for changes.

### 3. Check the Profile

View the profile status:

    foldersynka status my-project

### 4. Stop Synchronization

Stop the profile when synchronization is no longer required:

    foldersynka stop my-project

### 5. Restart Synchronization

Restart the profile with:

    foldersynka restart my-project

### 6. List Profiles

View all configured profiles:

    foldersynka list

### 7. Run Diagnostics

Check the FolderSynka environment:

    foldersynka doctor

A profile can also be started immediately when it is created:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project \
        --watch
        
## Commands

FolderSynka provides a command-line interface for managing synchronization
profiles.

### General Usage

    foldersynka <command> [options]

### Available Commands

| Command | Description |
|---|---|
| `create` | Create a new synchronization profile |
| `start` | Start synchronization for a profile |
| `stop` | Stop synchronization for a profile |
| `restart` | Restart synchronization for a profile |
| `status` | Show the status of a profile |
| `list` | List configured profiles |
| `remove` | Remove a synchronization profile |
| `doctor` | Diagnose the FolderSynka environment |
| `ignore` | Manage `.foldersynkaignore` files |
| `version` | Display the installed FolderSynka version |
| `help` | Display command help |

### Global Options

Show general help:

    foldersynka --help

or:

    foldersynka -h

Show the version:

    foldersynka --version

or:

    foldersynka -v

Command-specific help is also available:

    foldersynka help create

    foldersynka help start

    foldersynka help doctor

    foldersynka help ignore

### Create

Create a new synchronization profile:

    foldersynka create <profile> \
        --src <source> \
        --dest <destination>

Optional synchronization settings include:

    --compress
    --checksum
    --no-delete
    --watch

Example:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project \
        --compress \
        --checksum

### Start

Start a profile:

    foldersynka start my-project

### Stop

Stop a running profile:

    foldersynka stop my-project

### Restart

Restart a profile:

    foldersynka restart my-project

### Status

Display the current profile status:

    foldersynka status my-project

### List

List all configured profiles:

    foldersynka list

### Remove

Remove a profile:

    foldersynka remove my-project

### Doctor

Run environment and profile diagnostics:

    foldersynka doctor

A specific profile can also be targeted:

    foldersynka doctor my-project

### Ignore

Manage synchronization ignore rules:

    foldersynka ignore

For command-specific ignore functionality:

    foldersynka help ignore

### Version

Display the installed version:

    foldersynka version
    

## Testing

The repository includes an integration test suite for the main application
lifecycle.

Run:

    bash tests/test.sh

The test suite verifies:

- CLI version and help
- Profile creation and listing
- Profile configuration options
- Ignore-file creation and management
- Environment diagnostics
- Initial synchronization
- Event-driven synchronization
- Service start and stop
- Profile removal

The test suite uses temporary directories and a test service wrapper. It does
not modify the user's FolderSynka runtime.

## Profiles

FolderSynka uses named profiles to define synchronization relationships.

A profile contains the information required to synchronize one source
workspace with one destination workspace.

### Profile Structure

A typical profile consists of:

    Profile Name
        │
        ├── Source
        ├── Destination
        ├── Synchronization Settings
        ├── Runtime State
        └── Ignore Rules

Profiles are managed independently, allowing multiple projects to be
synchronized using different configurations.

### Creating a Profile

Create a profile with:

    foldersynka create <profile> \
        --src <source> \
        --dest <destination>

Example:

    foldersynka create game-engine \
        --src ~/storage/shared/GameEngine \
        --dest ~/projects/GameEngine

### Profile Names

Profile names are used by the FolderSynka CLI to identify synchronization
jobs.

For example:

    foldersynka start game-engine

    foldersynka status game-engine

    foldersynka stop game-engine

Use simple, descriptive names that identify the workspace being synchronized.

### Multiple Profiles

Multiple synchronization profiles can coexist.

For example:

    foldersynka create frontend \
        --src ~/storage/shared/Projects/frontend \
        --dest ~/projects/frontend

    foldersynka create backend \
        --src ~/storage/shared/Projects/backend \
        --dest ~/projects/backend

    foldersynka create game-engine \
        --src ~/storage/shared/Projects/game-engine \
        --dest ~/projects/game-engine

Each profile can then be managed independently:

    foldersynka start frontend

    foldersynka start backend

    foldersynka start game-engine

### Listing Profiles

Display configured profiles with:

    foldersynka list

### Inspecting a Profile

Check the current state of a profile with:

    foldersynka status <profile>

For example:

    foldersynka status game-engine

### Removing a Profile

Remove a profile with:

    foldersynka remove <profile>

Example:

    foldersynka remove game-engine

Removing a profile removes its FolderSynka configuration. The source and
destination workspace contents are treated separately from the profile
configuration.

### Profile Lifecycle

A typical profile lifecycle is:

    Create
      │
      ▼
    Configure
      │
      ▼
    Start
      │
      ▼
    Synchronize
      │
      ▼
    Stop
      │
      ▼
    Restart / Remove
    

## Ignore Files

FolderSynka supports per-source `.foldersynkaignore` files for excluding
files and directories from synchronization.

The ignore system is designed to work similarly to familiar ignore files such
as `.gitignore`.

### Default Ignore File

When a profile is created, FolderSynka initializes a `.foldersynkaignore`
file in the source directory if one does not already exist.

Example:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project

The resulting source directory may contain:

    my-project/
    ├── .foldersynkaignore
    ├── src/
    ├── package.json
    └── ...

Existing `.foldersynkaignore` files are preserved.

### Managing Ignore Files

FolderSynka provides an `ignore` command for managing ignore rules.

View the available ignore commands with:

    foldersynka ignore --help

or:

    foldersynka help ignore

### Ignore Patterns

The ignore file uses patterns to identify files and directories that should
not participate in synchronization.

For example:

    # Dependencies

    node_modules/
    vendor/

    # Build output

    dist/
    build/

    # Environment files

    .env
    .env.*

    # Logs

    *.log
    logs/

### Comments

Lines beginning with `#` are treated as comments.

For example:

    # Ignore generated build files

    dist/

Comments are useful for organizing larger ignore files.

### Common Patterns

A typical `.foldersynkaignore` may contain:

    .git/
    node_modules/
    dist/
    build/
    coverage/
    .env
    .env.*
    *.log
    .vscode/
    .idea/

FolderSynka also provides a default ignore template containing common
development, build, environment, IDE, operating-system, and temporary files.

### Per-Profile Ignore Rules

Ignore rules belong to the source workspace of a profile.

This allows different projects to maintain different synchronization rules.

For example:

    ~/storage/shared/ProjectA/.foldersynkaignore

and:

    ~/storage/shared/ProjectB/.foldersynkaignore

can contain completely different rules.

### Important

Ignore rules affect synchronization behavior. Files excluded by the ignore
configuration are not intended to be synchronized to the destination.

The ignore file should therefore be treated as part of the synchronization
configuration for the workspace.


## Configuration

FolderSynka separates application configuration, profile configuration, and
runtime state.

This separation keeps the installed application independent from individual
synchronization profiles.

### Application Installation

The installed application is located under:

    $PREFIX/share/foldersynka/

The main executable is available through:

    $PREFIX/bin/foldersynka

### Runtime Directory

FolderSynka keeps runtime data under:

    $HOME/.foldersynka/

Runtime data may include profile state, service information, locks, and other
files required while FolderSynka is operating.

Runtime data is intentionally kept outside the installed application.

### Profile Configuration

Each synchronization profile has its own configuration.

A profile defines at minimum:

    Profile Name
    Source Directory
    Destination Directory

Additional synchronization settings may also be associated with the profile,
including options controlling rsync behavior and file watching.

Profiles should be managed through the FolderSynka CLI rather than manually
editing internal configuration files.

### Creating Configuration

The recommended way to create a profile is:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project

FolderSynka validates the supplied configuration before creating the profile.

### Synchronization Options

Profiles can be created with additional synchronization options.

For example:

    foldersynka create my-project \
        --src ~/storage/shared/Documents/my-project \
        --dest ~/projects/my-project \
        --compress \
        --checksum \
        --no-delete

Available options include:

    --compress
        Enable rsync compression.

    --checksum
        Enable checksum-based file comparison.

    --no-delete
        Prevent synchronization from deleting files removed from the source.

    --watch
        Start the profile after creation.

### Configuration Validation

FolderSynka validates important configuration components before operations
are performed.

Validation can include:

    - Profile name
    - Source directory
    - Destination directory
    - Profile configuration
    - Ignore file
    - Runtime environment
    - Required dependencies
    - Generated service

Run diagnostics with:

    foldersynka doctor

For a specific profile:

    foldersynka doctor my-project

### Environment

FolderSynka is designed for the Termux environment and relies on the Termux
filesystem layout.

Important environment variables include:

    HOME
    PREFIX

The application also maintains its own installation and runtime paths based
on the active Termux environment.

### Configuration Principle

FolderSynka follows a simple separation:

    Application
        $PREFIX/share/foldersynka/

    CLI
        $PREFIX/bin/foldersynka

    Runtime
        $HOME/.foldersynka/

    Workspace
        User-defined source directory

    Destination
        User-defined synchronization directory

This structure allows the application, runtime state, and synchronized
workspaces to remain independent.


## Service Management

FolderSynka uses Termux services to manage long-running synchronization
profiles.

A profile can be started, stopped, restarted, and inspected independently.

### Starting a Profile

Start a synchronization profile with:

    foldersynka start <profile>

Example:

    foldersynka start my-project

When started, FolderSynka creates or uses the corresponding service for the
profile and begins synchronization.

### Stopping a Profile

Stop a running profile with:

    foldersynka stop <profile>

Example:

    foldersynka stop my-project

Stopping a profile stops its synchronization service.

### Restarting a Profile

Restart a profile with:

    foldersynka restart <profile>

Example:

    foldersynka restart my-project

This is useful after changing configuration or when restarting the watcher.

### Checking Service Status

Check the status of a profile with:

    foldersynka status <profile>

Example:

    foldersynka status my-project

The status command provides information about the configured profile and its
current service state.

### Generated Services

FolderSynka generates the required service definition for each profile.

Generated services are managed separately from the application source code
and runtime configuration.

This allows each profile to operate as an independent synchronization
service.

### Service Lifecycle

The normal service lifecycle is:

    Profile Created
          │
          ▼
    Service Generated
          │
          ▼
        Start
          │
          ▼
       Running
          │
          ├──────────────┐
          ▼              ▼
        Stop           Restart
          │              │
          ▼              │
       Stopped ◄─────────┘

### Multiple Services

Multiple profiles can run independently.

For example:

    foldersynka start frontend
    foldersynka start backend
    foldersynka start game-engine

Each profile maintains its own synchronization service.

### Service Requirements

Service management requires the Termux service environment to be available.

FolderSynka expects the `sv` command and `termux-services` environment to be
properly configured.

If service management is not working, run:

    foldersynka doctor

The diagnostics command checks the service environment and reports detected
problems.


## Diagnostics

FolderSynka includes a diagnostic command for checking the installation,
runtime environment, profiles, services, and required dependencies.

### Running Diagnostics

Run:

    foldersynka doctor

The diagnostic command performs a series of checks and reports the current
state of the FolderSynka environment.

### What Is Checked

Diagnostics may include checks for:

- FolderSynka installation paths
- Required directories
- Required commands and dependencies
- Runtime directories
- Profile configuration
- Profile source and destination paths
- Service availability
- Service state
- File permissions
- Synchronization configuration

### Example

Run:

    foldersynka doctor

A successful diagnostic run should report that the required components are
available and correctly configured.

If a problem is detected, the diagnostic output identifies the affected
component so it can be investigated.

### Installation Problems

If FolderSynka reports that it is not installed correctly, verify that the
application exists under:

    $PREFIX/share/foldersynka/

and that the executable exists at:

    $PREFIX/bin/foldersynka

The installation can be repaired by running the installer again from the
repository.

### Service Problems

If a profile cannot be started or its service is not running, first run:

    foldersynka doctor

Then inspect the affected profile:

    foldersynka status <profile>

If necessary, restart the profile:

    foldersynka restart <profile>

### Profile Problems

For profile-specific problems, verify that:

- The profile exists.
- The source directory exists.
- The destination directory is accessible.
- The profile configuration is valid.
- The ignore file is present when required.
- The synchronization service is available.

Use:

    foldersynka list

to inspect configured profiles.

### Debugging Approach

When troubleshooting FolderSynka, use the following order:

    1. Run foldersynka doctor
    2. Check foldersynka list
    3. Check foldersynka status <profile>
    4. Inspect the profile configuration
    5. Check the ignore file
    6. Restart the affected profile
    7. Inspect logs if necessary

This keeps troubleshooting focused on the environment, profile configuration,
service state, and synchronization engine in that order.


## Project Structure

FolderSynka is organized into separate layers for command handling,
configuration, validation, synchronization, services, and shared utilities.

The main repository structure is:

    foldersynka/
    ├── bin/
    │   └── foldersynka
    │
    ├── core/
    │   ├── cli/
    │   │   ├── commands/
    │   │   ├── help.sh
    │   │   └── router.sh
    │   │
    │   ├── config/
    │   │   ├── config.sh
    │   │   ├── defaults.sh
    │   │   ├── ignore.sh
    │   │   ├── paths.sh
    │   │   ├── profile.sh
    │   │   ├── runtime.sh
    │   │   └── state.sh
    │   │
    │   ├── engine/
    │   │   ├── rsync.sh
    │   │   ├── sync-engine.sh
    │   │   └── watcher.sh
    │   │
    │   ├── lib/
    │   │   ├── constants.sh
    │   │   ├── environment.sh
    │   │   ├── error-codes.sh
    │   │   ├── error-registry.sh
    │   │   ├── errors.sh
    │   │   ├── exit-codes.sh
    │   │   ├── process.sh
    │   │   ├── strings.sh
    │   │   └── validation-context.sh
    │   │
    │   ├── services/
    │   │   └── service-generator.sh
    │   │
    │   ├── templates/
    │   │   └── foldersynkaignore
    │   │
    │   ├── utils/
    │   │   ├── arguments.sh
    │   │   ├── filesystem.sh
    │   │   ├── logger.sh
    │   │   ├── terminal.sh
    │   │   └── validation.sh
    │   │
    │   └── validation/
    │       ├── create.sh
    │       ├── doctor.sh
    │       ├── pipeline.sh
    │       ├── remove.sh
    │       ├── start.sh
    │       ├── stop.sh
    │       └── sync.sh
    │
    ├── CHANGELOG.md
    ├── LICENSE
    ├── README.md
    ├── VERSION
    ├── change.md
    ├── .editorconfig
    ├── .gitignore
    ├── install.sh
    └── uninstall.sh

### CLI

The `core/cli/` directory contains the command-line interface.

The router receives commands and dispatches them to the appropriate command
implementation.

    core/cli/router.sh

Individual commands are located under:

    core/cli/commands/

### Configuration

The `core/config/` directory contains application, profile, runtime, state,
path, and ignore-file configuration logic.

### Engine

The `core/engine/` directory contains the synchronization engine.

It is responsible for coordinating:

- `rsync` synchronization
- Filesystem watching
- Synchronization events

### Library

The `core/lib/` directory contains shared application primitives such as
constants, environment handling, error definitions, exit codes, process
management, strings, and validation context.

### Services

The `core/services/` directory contains service-generation logic used to
create the runtime service definition for synchronization profiles.

### Templates

The `core/templates/` directory contains reusable application templates.

The default `.foldersynkaignore` template is stored here:

    core/templates/.foldersynkaignore

### Utilities

The `core/utils/` directory contains shared utilities used throughout the
application, including argument parsing, filesystem operations, logging,
terminal output, and validation helpers.

### Validation

The `core/validation/` directory contains validation modules used by the
validation pipeline and individual CLI operations.

Validation is kept separate from command implementations so that common
preconditions can be reused consistently across the application.

### Executable

The main user-facing executable is:

    bin/foldersynka

After installation, it becomes:

    $PREFIX/bin/foldersynka

### Installation Scripts

The repository provides:

    install.sh
    uninstall.sh

These scripts manage installation and removal of the FolderSynka application
from the Termux environment.


## Development

FolderSynka is developed as a modular Bash application for Termux.

The repository is structured so that CLI commands, configuration, validation,
synchronization, services, and shared utilities remain separated.

### Clone the Repository

Clone the repository and enter the project directory:

    git clone <repository-url>

    cd foldersynka

### Run From the Repository

During development, FolderSynka can be tested directly from the repository
before installation.

Make the main executable available:

    chmod +x bin/foldersynka

The project can then be executed through the repository entry point once the
required environment variables and project paths are initialized.

The installation process should only be used after repository-level behavior
has been verified.

### Shell Validation

All Bash scripts should pass shell syntax validation.

Run:

    find . -type f -name "*.sh" -not -path "./.git/*" -print0 |
    while IFS= read -r -d '' file; do
        bash -n "$file" || exit 1
    done

### Git Checks

Before committing changes, inspect the working tree:

    git status

Check for whitespace problems:

    git diff --check

Review staged changes with:

    git diff --cached

### Development Workflow

A typical development workflow is:

    1. Make a focused change.
    2. Validate the affected scripts.
    3. Run the relevant tests.
    4. Inspect the Git diff.
    5. Update documentation when required.
    6. Update the changelog when appropriate.
    7. Commit the change.

### Change Tracking

During active development, `change.md` is used as the internal development
ledger.

It records completed implementation phases and significant architectural
changes.

Once the development and verification process is complete, the relevant
information from `change.md` is consolidated into `CHANGELOG.md`.

### Testing

Testing is performed against the actual application rather than relying only
on shell syntax checks.

The project testing process includes verification of:

- Repository execution
- Installation
- CLI commands
- Profile creation
- Profile configuration
- Ignore-file handling
- Synchronization
- Service management
- Diagnostics
- Uninstallation

Testing is documented and expanded as the project approaches release.

### Development Principles

Changes should preserve the project's architectural separation and avoid
introducing unnecessary dependencies.

When modifying an existing subsystem:

- Reuse existing configuration and validation layers.
- Keep command implementations focused on CLI behavior.
- Keep synchronization logic inside the engine.
- Keep reusable functionality inside the appropriate library or utility.
- Preserve consistent error handling and exit codes.
- Update documentation when user-facing behavior changes.


## Roadmap

FolderSynka is being developed incrementally, with stability and a clear
architecture taking priority over feature expansion.

### Current Development

The current development cycle focuses on establishing a reliable core
synchronization system and a complete Termux CLI.

Current areas include:

- Profile management
- Synchronization engine
- Filesystem watching
- Ignore-file management
- Service management
- Validation and diagnostics
- Installation and uninstallation
- CLI consistency
- Repository and release preparation
- Automated testing

### Planned

Future development may include:

- Expanded synchronization configuration
- Improved synchronization reporting
- More detailed service status information
- Improved error messages and recovery guidance
- Additional diagnostic checks
- Expanded automated test coverage
- Improved logging and debugging tools
- Safer configuration migration
- Release packaging
- Improved documentation
- Additional Termux integrations

### Future Considerations

Potential future capabilities may include:

- Multiple synchronization strategies
- More advanced synchronization policies
- Profile import and export
- Configuration backup and restoration
- Improved event handling
- Performance optimizations for large workspaces
- Additional platform support where practical

Features will be evaluated based on reliability, maintainability, and usefulness
rather than added solely for feature completeness.

### Development Philosophy

FolderSynka is intended to remain:

- Lightweight
- Developer-focused
- Transparent
- Scriptable
- Modular
- Termux-friendly
- Easy to inspect and maintain

The roadmap may change as real-world usage and testing reveal new
requirements.


## Contributing

Contributions are welcome.

Before making changes:

1. Fork the repository.
2. Create a feature or fix branch.
3. Keep changes focused and clearly scoped.
4. Follow the existing shell scripting and project structure conventions.
5. Validate shell scripts with `bash -n`.
6. Run the relevant FolderSynka tests before submitting changes.
7. Update documentation when behavior or commands change.
8. Update the changelog when appropriate.

### Development Guidelines

FolderSynka is developed with a focus on:

- Clear separation between CLI, configuration, validation, engine, and utility layers.
- Predictable command behavior.
- Explicit validation and error handling.
- Portable Bash where practical.
- Minimal dependencies.
- Readable and maintainable shell code.

Please avoid unrelated changes in the same commit or pull request.

For larger changes, open an issue or discussion first so the proposed architecture can be reviewed before implementation.

## Release

Current release: **v1.0.0**

FolderSynka v1.0.0 is the first stable release boundary of the current
application feature set. The release focuses on reliable profile management,
one-way synchronization, filesystem watching, ignore-file management,
Termux service integration, diagnostics, and predictable CLI behavior.
