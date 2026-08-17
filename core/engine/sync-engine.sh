#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/engine/sync-engine.sh
#
# Description:
#   FolderSynka synchronization engine.
#
# Responsibilities:
#   • Coordinate synchronization
#   • Manage watcher lifecycle
#   • Handle filesystem events
#   • Prevent concurrent synchronization
#   • Persist runtime state
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/utils/logger.sh"
source "${FS_HOME}/core/utils/validation.sh"

source "${FS_HOME}/core/engine/rsync.sh"
source "${FS_HOME}/core/engine/watcher.sh"

###############################################################################
# Globals
###############################################################################

FS_SYNC_PROFILE=""

###############################################################################
# Synchronization
###############################################################################

fs_sync_run() {
    local profile="$1"

    fs_profile_load "$profile"

    fs_state_mark_syncing "$profile"

    if fs_rsync_execute \
        "$profile" \
        "$FS_PROFILE_SOURCE" \
        "$FS_PROFILE_DESTINATION"
    then
        fs_state_touch_sync "$profile"
        fs_state_clear_error "$profile"
        fs_state_reset_retry "$profile"
        fs_state_mark_healthy "$profile"

        return 0
    fi

    fs_state_set_error \
        "$profile" \
        "Synchronization failed."

    fs_state_mark_warning "$profile"
    fs_state_increment_retry "$profile"

    return 1
}

###############################################################################
# Watcher Callback
###############################################################################

fs_sync_event() {
    local directory="$1"
    local file="$2"
    local event="$3"

    local profile="$FS_SYNC_PROFILE"

    [[ -n "$profile" ]] || return 1

    fs_log_debug \
        "$profile" \
        "${event}: ${directory}${file}"

    if ! fs_state_lock_acquire "$profile"; then
        fs_log_debug \
            "$profile" \
            "Synchronization already running."

        return 0
    fi

    if fs_sync_run "$profile"; then
        fs_log_debug \
            "$profile" \
            "Event synchronization completed."
    else
        fs_log_error \
            "$profile" \
            "Event synchronization failed."
    fi

    fs_state_lock_release "$profile"
}

###############################################################################
# Synchronize Once
###############################################################################

fs_sync_once() {
    local profile="$1"

    fs_validate_profile_exists "$profile" || return 1
    fs_validate_profile_configuration "$profile" || return 1

    if ! fs_state_lock_acquire "$profile"; then
        fs_log_warn \
            "$profile" \
            "Synchronization is already running."

        return 1
    fi

    if fs_sync_run "$profile"; then
        fs_state_lock_release "$profile"
        return 0
    fi

    fs_state_lock_release "$profile"

    return 1
}

###############################################################################
# Start Engine
###############################################################################

fs_sync_start() {
    local profile="$1"

    fs_validate_profile_exists "$profile" || return 1
    fs_validate_profile_configuration "$profile" || return 1
    fs_validate_system || return 1

    if fs_state_is_running "$profile"; then
        fs_log_warn \
            "$profile" \
            "Synchronization engine is already running."

        return 1
    fi

    fs_profile_load "$profile"

    FS_SYNC_PROFILE="$profile"

    fs_state_mark_starting "$profile"
    fs_state_clear_error "$profile"

    fs_log_info \
        "$profile" \
        "Starting synchronization engine."

    if ! fs_state_lock_acquire "$profile"; then
        fs_state_mark_stopped "$profile"

        fs_log_error \
            "$profile" \
            "Unable to acquire synchronization lock."

        FS_SYNC_PROFILE=""

        return 1
    fi

    if ! fs_sync_run "$profile"; then
        fs_state_lock_release "$profile"
        fs_state_mark_stopped "$profile"

        fs_log_error \
            "$profile" \
            "Initial synchronization failed."

        FS_SYNC_PROFILE=""

        return 1
    fi

    fs_state_lock_release "$profile"

    if ! fs_watcher_start \
        "$profile" \
        "$FS_PROFILE_SOURCE" \
        fs_sync_event
    then
        fs_state_set_error \
            "$profile" \
            "Unable to start filesystem watcher."

        fs_state_mark_unhealthy "$profile"
        fs_state_mark_stopped "$profile"

        FS_SYNC_PROFILE=""

        return 1
    fi

    fs_state_pid_write \
        "$profile" \
        "$FS_WATCHER_PID"

    fs_state_service_write \
        "$profile" \
        "running"

    fs_state_mark_running "$profile"

    fs_log_success \
        "$profile" \
        "Synchronization engine started."

    return 0
}

###############################################################################
# Stop Engine
###############################################################################

fs_sync_stop() {
    local profile="${1:-$FS_SYNC_PROFILE}"

    [[ -n "$profile" ]] || return 0

    fs_state_mark_stopping "$profile"

    fs_watcher_stop "$profile"

    fs_state_pid_remove "$profile"
    fs_state_lock_release "$profile"

    fs_state_service_write \
        "$profile" \
        "stopped"

    fs_state_mark_stopped "$profile"

    fs_log_info \
        "$profile" \
        "Synchronization engine stopped."

    if [[ "$FS_SYNC_PROFILE" == "$profile" ]]; then
        FS_SYNC_PROFILE=""
    fi
}

###############################################################################
# Restart Engine
###############################################################################

fs_sync_restart() {
    local profile="$1"

    fs_sync_stop "$profile"

    fs_sync_start "$profile"
}

###############################################################################
# Status
###############################################################################

fs_sync_running() {
    local profile="${1:-$FS_SYNC_PROFILE}"

    [[ -n "$profile" ]] || return 1

    fs_state_is_running "$profile"
}

###############################################################################
# Current Profile
###############################################################################

fs_sync_profile() {
    printf '%s\n' "$FS_SYNC_PROFILE"
}

###############################################################################
# Engine Information
###############################################################################

fs_sync_info() {
    local profile="${1:-$FS_SYNC_PROFILE}"

    [[ -n "$profile" ]] || return 1

    fs_state_load "$profile"

    printf "Profile : %s\n" "$profile"
    printf "State   : %s\n" "$FS_STATE_STATUS"
    printf "Health  : %s\n" "$FS_STATE_HEALTH"
    printf "Service : %s\n" "$FS_STATE_SERVICE"

    if fs_watcher_running; then
        printf "Watcher : running\n"
    else
        printf "Watcher : stopped\n"
    fi

    if fs_state_lock_exists "$profile"; then
        printf "Lock    : acquired\n"
    else
        printf "Lock    : released\n"
    fi

    if fs_state_pid_exists "$profile"; then
        printf "PID     : %s\n" \
            "$(fs_state_pid_read "$profile")"
    else
        printf "PID     : none\n"
    fi

    printf "Last Sync    : %s\n" "$FS_STATE_LAST_SYNC"
    printf "Files Synced : %s\n" "$FS_STATE_FILES_SYNCED"
    printf "Bytes Synced : %s\n" "$FS_STATE_BYTES_SYNCED"
    printf "Retry Count  : %s\n" "$FS_STATE_RETRY_COUNT"

    if [[ -n "$FS_STATE_LAST_ERROR" ]]; then
        printf "Last Error   : %s\n" "$FS_STATE_LAST_ERROR"
    fi
}

###############################################################################
# End of File
###############################################################################