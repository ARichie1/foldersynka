#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/status.sh
#
# Description:
#   Display profile runtime and service status.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/services/service-generator.sh"

###############################################################################
# Help
###############################################################################

fs_status_help() {

    cat <<EOF

Show the status of a FolderSynka profile.

Usage

    foldersynka status <profile>

EOF

}

###############################################################################
# Main
###############################################################################

fs_command_status() {

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        fs_status_help
        return 0
    fi

    local profile="${1:-}"

    if [[ -z "$profile" ]]; then
        fs_status_help
        return 1
    fi

    if ! fs_profile_exists "$profile"; then
        printf 'Profile not found: %s\n' "$profile" >&2
        return 1
    fi

    fs_profile_load "$profile"
    fs_state_load "$profile"

    printf '\n'
    printf 'Profile: %s\n' "$profile"
    printf '%s\n' '----------------------------------------'
    printf 'Source       : %s\n' "$FS_PROFILE_SOURCE"
    printf 'Destination  : %s\n' "$FS_PROFILE_DESTINATION"
    printf 'Status       : %s\n' "$FS_STATE_STATUS"
    printf 'Health       : %s\n' "$FS_STATE_HEALTH"
    printf 'Service      : %s\n' "$FS_STATE_SERVICE"
    printf 'PID          : %s\n' "${FS_STATE_PID:-none}"
    printf 'Last Sync    : %s\n' "${FS_STATE_LAST_SYNC:-never}"
    printf 'Files Synced : %s\n' "$FS_STATE_FILES_SYNCED"
    printf 'Bytes Synced : %s\n' "$FS_STATE_BYTES_SYNCED"
    printf 'Retry Count  : %s\n' "$FS_STATE_RETRY_COUNT"

    if [[ -n "$FS_STATE_LAST_ERROR" ]]; then
        printf 'Last Error   : %s\n' "$FS_STATE_LAST_ERROR"
    fi

    printf '\n'

}
    
###############################################################################
# Execute
###############################################################################

fs_command_status "$@"