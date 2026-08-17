#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/remove.sh
#
# Description:
#   Remove a FolderSynka synchronization profile.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/validation/pipeline.sh"
source "${FS_HOME}/core/services/service-generator.sh"

###############################################################################
# Help
###############################################################################

fs_remove_help() {

    cat <<EOF

Remove a FolderSynka profile.

Usage

    foldersynka remove <profile>

EOF

}

###############################################################################
# Main
###############################################################################

fs_command_remove() {

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        fs_remove_help
        return 0
    fi

    local profile="${1:-}"

    if [[ -z "$profile" ]]; then
        fs_remove_help
        return 1
    fi

    ###########################################################################
    # Validation
    ###########################################################################

    fs_run_validation_pipeline \
        remove \
        "$profile"

    ###########################################################################
    # Service
    ###########################################################################

    if fs_service_exists "$profile"; then
        fs_service_remove "$profile"
    fi

    ###########################################################################
    # Runtime State
    ###########################################################################

    fs_state_destroy "$profile"

    ###########################################################################
    # Profile
    ###########################################################################

    fs_profile_delete "$profile"

    printf 'Profile removed: %s\n' "$profile"

}

###############################################################################
# Execute
###############################################################################

fs_command_remove "$@"