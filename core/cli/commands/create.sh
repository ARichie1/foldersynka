#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/create.sh
#
# Description:
#   Create a new FolderSynka synchronization profile.
#
# Responsibilities:
#   • Parse create command arguments
#   • Run create validation pipeline
#   • Create destination directory
#   • Create profile configuration
#   • Initialize the profile ignore file
#   • Optionally start the profile
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/ignore.sh"

source "${FS_HOME}/core/utils/arguments.sh"
source "${FS_HOME}/core/utils/logger.sh"

source "${FS_HOME}/core/validation/pipeline.sh"

###############################################################################
# Help
###############################################################################

fs_create_help() {

    cat <<EOF

Create a new FolderSynka profile.

Usage

    foldersynka create <profile> --src <source> --dest <destination>

Options

    --src, -s
        Source directory.

    --dest, -d
        Destination directory.

    --mode copy|mirror|bidirectional
        Reconciliation mode (default: copy).

    --json
        Emit the created profile as JSON.

    --compress
        Enable rsync compression.

    --checksum
        Enable checksum comparison.

    --no-delete
        Disable deletion of removed files.

    --watch
        Start the profile after creation.

    -h, --help
        Show this help.

EOF

}

###############################################################################
# Main
###############################################################################

fs_command_create() {

    fs_args_parse_create "$@" || return 1

    if fs_args_has help; then
        fs_create_help
        return 0
    fi

    local profile
    local source
    local destination

    profile="$(fs_args_get profile)"
    source="$(fs_args_get src)"
    destination="$(fs_args_get dest)"
    FS_CREATE_MODE="$(fs_args_get mode)"
    FS_CREATE_MODE="${FS_CREATE_MODE:-copy}"
    if fs_args_has delete && [[ "$FS_CREATE_MODE" != copy ]]; then
        fs_log_error "--no-delete is only compatible with --mode copy."
        return 1
    fi

    ###########################################################################
    # Required Arguments
    ###########################################################################

    if [[ -z "$source" ]]; then
        fs_log_error "--src is required."
        return 1
    fi

    if [[ -z "$destination" ]]; then
        fs_log_error "--dest is required."
        return 1
    fi

    ###########################################################################
    # Runtime
    ###########################################################################

    fs_runtime_ensure || return 1

    ###########################################################################
    # Validation Pipeline
    ###########################################################################

    fs_run_validation_pipeline \
        create \
        "$profile" \
        "$source" \
        "$destination" || return 1

    ###########################################################################
    # Destination
    ###########################################################################

    mkdir -p "$destination" || return 1

    ###########################################################################
    # Profile
    ###########################################################################

    fs_profile_create \
        "$profile" \
        "$source" \
        "$destination" || return 1

    fs_profile_set "$profile" MODE "${FS_CREATE_MODE:-copy}" || return 1
    if [[ "$FS_CREATE_MODE" == mirror || "$FS_CREATE_MODE" == bidirectional ]]; then
        fs_profile_set "$profile" DELETE true || return 1
    fi

    if fs_args_has compress; then
        fs_profile_set "$profile" COMPRESS "true"
    fi

    if fs_args_has checksum; then
        fs_profile_set "$profile" CHECKSUM "true"
    fi

    if fs_args_has delete; then
        fs_profile_set "$profile" DELETE "$(fs_args_get delete)"
    fi

    ###########################################################################
    # Ignore File
    ###########################################################################

    fs_ignore_init "$profile" || return 1

    ###########################################################################
    # Success
    ###########################################################################

    printf '\n'
    printf 'Profile created successfully.\n\n'
    printf 'Profile      : %s\n' "$profile"
    printf 'Source       : %s\n' "$source"
    printf 'Destination  : %s\n' "$destination"
    printf '\n'

    printf 'Next steps\n'
    printf '%s\n' '----------'
    printf 'foldersynka start %s\n' "$profile"

    ###########################################################################
    # Optional Start
    ###########################################################################

    if [[ "$(fs_args_get watch)" == "true" ]]; then

        printf '\nStarting profile...\n\n'

        bash "${FS_HOME}/core/cli/commands/start.sh" "$profile"

    fi

}

###############################################################################
# Execute
###############################################################################

if [[ " $* " == *" --json "* ]]; then
    if fs_command_create "$@" >&2; then
        exec bash "${FS_HOME}/core/cli/commands/bridge.sh" inspect "${1:-}" --json
    else
        printf '%s\n' '{"schemaVersion":1,"operation":"create","ok":false,"error":{"code":"CREATE_FAILED"}}'
        exit 2
    fi
else
    fs_command_create "$@"
fi
