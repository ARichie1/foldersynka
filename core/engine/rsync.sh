#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/engine/rsync.sh
#
# Description:
#   Rsync abstraction layer.
#
# Responsibilities:
#   • Validate rsync availability
#   • Build rsync commands
#   • Execute synchronization
#   • Perform dry runs
#   • Synchronize profiles
#   • Expose rsync information
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/utils/logger.sh"
source "${FS_HOME}/core/utils/validation.sh"

###############################################################################
# Globals
###############################################################################

FS_RSYNC_COMMAND=()

###############################################################################
# Availability
###############################################################################

fs_rsync_available() {
    fs_validate_rsync
}

###############################################################################
# Build Command
###############################################################################

fs_rsync_build_command() {
    local source="$1"
    local destination="$2"

    local ignore_file

    ignore_file="${source}/${FS_PROFILE_IGNORE_FILE}"

    FS_RSYNC_COMMAND=(
        rsync
        -a
    )

    if [[ "${FS_PROFILE_COMPRESS}" == "true" ]]; then
        FS_RSYNC_COMMAND+=(-z)
    fi

    if [[ "${FS_PROFILE_CHECKSUM}" == "true" ]]; then
        FS_RSYNC_COMMAND+=(--checksum)
    fi

    if [[ "${FS_PROFILE_DELETE}" == "true" ]]; then
        FS_RSYNC_COMMAND+=(--delete)
    fi

    if [[ "${FS_PROFILE_FOLLOW_SYMLINKS}" == "true" ]]; then
        FS_RSYNC_COMMAND+=(-L)
    fi

    if [[ -f "$ignore_file" ]]; then
        FS_RSYNC_COMMAND+=(
            "--exclude-from=${ignore_file}"
        )
    fi

    FS_RSYNC_COMMAND+=(
        "${source}/"
        "${destination}/"
    )
}

###############################################################################
# Execute
###############################################################################

fs_rsync_execute() {
    local profile="$1"
    local source="$2"
    local destination="$3"

    fs_rsync_available || return 1

    fs_validate_source "$source" || return 1
    fs_validate_destination "$destination" || return 1
    fs_validate_ignore_file "$source" || return 1

    fs_rsync_build_command \
        "$source" \
        "$destination"

    fs_log_debug \
                "Starting synchronization."

    if "${FS_RSYNC_COMMAND[@]}"; then
        fs_log_info \
                        "Synchronization completed."

        return 0
    fi

    fs_log_error \
                "Synchronization failed."

    return 1
}

###############################################################################
# Dry Run
###############################################################################

fs_rsync_dry_run() {
    local profile="$1"
    local source="$2"
    local destination="$3"

    fs_rsync_available || return 1

    fs_validate_source "$source" || return 1
    fs_validate_destination "$destination" || return 1
    fs_validate_ignore_file "$source" || return 1

    fs_rsync_build_command \
        "$source" \
        "$destination"

    local command=(
        "${FS_RSYNC_COMMAND[@]}"
        --dry-run
    )

    fs_log_debug \
                "Running synchronization dry run."

    "${command[@]}"
}

###############################################################################
# Synchronize Profile
###############################################################################

fs_rsync_profile() {
    local profile="$1"

    fs_profile_load "$profile"

    fs_rsync_execute \
        "$profile" \
        "$FS_PROFILE_SOURCE" \
        "$FS_PROFILE_DESTINATION"
}

###############################################################################
# Dry Run Profile
###############################################################################

fs_rsync_profile_dry_run() {
    local profile="$1"

    fs_profile_load "$profile"

    fs_rsync_dry_run \
        "$profile" \
        "$FS_PROFILE_SOURCE" \
        "$FS_PROFILE_DESTINATION"
}

###############################################################################
# Print Command
###############################################################################

fs_rsync_print_command() {
    printf '%q ' "${FS_RSYNC_COMMAND[@]}"
    printf '\n'
}

###############################################################################
# Version
###############################################################################

fs_rsync_version() {
    fs_rsync_available || return 1

    rsync --version
}

###############################################################################
# End of File
###############################################################################