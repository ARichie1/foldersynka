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

    --compress
        Enable rsync compression.

    --checksum
        Enable checksum comparison.

    --no-delete
        Disable deletion of removed files.

    --interval
        Set watcher debounce interval.

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

    fs_args_parse_create "$@"

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
    # Validation Pipeline
    ###########################################################################

    fs_run_validation_pipeline \
        create \
        "$profile" \
        "$source" \
        "$destination"

    ###########################################################################
    # Destination
    ###########################################################################

    mkdir -p "$destination"

    ###########################################################################
    # Profile
    ###########################################################################

    fs_profile_create \
        "$profile" \
        "$source" \
        "$destination"

    ###########################################################################
    # Ignore File
    ###########################################################################

    fs_ignore_init "$source"

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
    printf '----------\n'
    printf 'foldersynka start %s\n' "$profile"

    ###########################################################################
    # Optional Start
    ###########################################################################

    if [[ "$(fs_args_get watch)" == "true" ]]; then

        printf '\nStarting profile...\n\n'

        foldersynka start "$profile"

    fi

}

###############################################################################
# Execute
###############################################################################

fs_command_create "$@"