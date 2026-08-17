#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/config/state.sh
#
# Description:
#   Runtime state manager.
#
# Responsibilities:
#   • Initialize profile runtime state
#   • Load and persist runtime state
#   • Manage profile PID state
#   • Manage profile synchronization locks
#   • Manage profile status
#   • Manage profile service state
#   • Manage runtime health and synchronization statistics
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"

###############################################################################
# Internal Helpers
###############################################################################

fs_state_file() {

    local profile="$1"

    printf "%s\n" "$(fs_profile_runtime_file "$profile")"

}

fs_state_directory() {

    local profile="$1"

    printf "%s\n" "$(fs_profile_state_dir "$profile")"

}

fs_state_load_variables() {

    local file="$1"

    # shellcheck disable=SC1090
    source "$file"

    FS_STATE_STATUS="${STATUS:-stopped}"
    FS_STATE_PID="${PID:-}"
    FS_STATE_LAST_SYNC="${LAST_SYNC:-}"
    FS_STATE_FILES_SYNCED="${FILES_SYNCED:-0}"
    FS_STATE_BYTES_SYNCED="${BYTES_SYNCED:-0}"
    FS_STATE_LAST_ERROR="${LAST_ERROR:-}"
    FS_STATE_RETRY_COUNT="${RETRY_COUNT:-0}"
    FS_STATE_HEALTH="${HEALTH:-healthy}"
    FS_STATE_SERVICE="${SERVICE:-}"

}

###############################################################################
# Initialize State
###############################################################################

fs_state_init() {

    local profile="$1"
    local directory
    local file

    directory="$(fs_state_directory "$profile")"
    file="$(fs_state_file "$profile")"

    mkdir -p "$directory"

    [[ -f "$file" ]] && return 0

    cat > "$file" <<EOF
###############################################################################
# FolderSynka Runtime State
###############################################################################

STATUS="stopped"
PID=""
LAST_SYNC=""
FILES_SYNCED=0
BYTES_SYNCED=0
LAST_ERROR=""
RETRY_COUNT=0
HEALTH="healthy"
SERVICE="$(fs_service_name "$profile")"
EOF

}

###############################################################################
# State Exists
###############################################################################

fs_state_exists() {

    local profile="$1"

    [[ -f "$(fs_state_file "$profile")" ]]

}

###############################################################################
# Load State
###############################################################################

fs_state_load() {

    local profile="$1"
    local file

    fs_state_init "$profile"

    file="$(fs_state_file "$profile")"

    fs_state_load_variables "$file"

}

###############################################################################
# Reload Current Profile State
###############################################################################

fs_state_reload() {

    [[ -n "${FS_PROFILE_NAME:-}" ]] || return 1

    fs_state_load "$FS_PROFILE_NAME"

}

###############################################################################
# Persist State
###############################################################################

fs_state_commit() {

    local profile="$1"
    local file

    file="$(fs_state_file "$profile")"

    mkdir -p "$(dirname "$file")"

    cat > "$file" <<EOF
###############################################################################
# FolderSynka Runtime State
###############################################################################

STATUS="${FS_STATE_STATUS}"
PID="${FS_STATE_PID}"
LAST_SYNC="${FS_STATE_LAST_SYNC}"
FILES_SYNCED=${FS_STATE_FILES_SYNCED}
BYTES_SYNCED=${FS_STATE_BYTES_SYNCED}
LAST_ERROR="${FS_STATE_LAST_ERROR}"
RETRY_COUNT=${FS_STATE_RETRY_COUNT}
HEALTH="${FS_STATE_HEALTH}"
SERVICE="${FS_STATE_SERVICE}"
EOF

}

###############################################################################
# State Save Alias
###############################################################################

fs_state_save() {

    fs_state_commit "$1"

}

###############################################################################
# Read State Value
###############################################################################

fs_state_get() {

    local profile="$1"
    local key="$2"

    fs_state_load "$profile"

    case "$key" in
        STATUS)
            printf "%s\n" "$FS_STATE_STATUS"
            ;;
        PID)
            printf "%s\n" "$FS_STATE_PID"
            ;;
        LAST_SYNC)
            printf "%s\n" "$FS_STATE_LAST_SYNC"
            ;;
        FILES_SYNCED)
            printf "%s\n" "$FS_STATE_FILES_SYNCED"
            ;;
        BYTES_SYNCED)
            printf "%s\n" "$FS_STATE_BYTES_SYNCED"
            ;;
        LAST_ERROR)
            printf "%s\n" "$FS_STATE_LAST_ERROR"
            ;;
        RETRY_COUNT)
            printf "%s\n" "$FS_STATE_RETRY_COUNT"
            ;;
        HEALTH)
            printf "%s\n" "$FS_STATE_HEALTH"
            ;;
        SERVICE)
            printf "%s\n" "$FS_STATE_SERVICE"
            ;;
        *)
            printf "Unknown runtime key: %s\n" "$key" >&2
            return 1
            ;;
    esac

}

###############################################################################
# Status API
###############################################################################

fs_state_status() {

    local profile="$1"

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_STATUS"

}

fs_state_mark_starting() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_STATUS="starting"
    fs_state_commit "$profile"

}

fs_state_mark_running() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_STATUS="running"
    fs_state_commit "$profile"

}

fs_state_mark_syncing() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_STATUS="syncing"
    fs_state_commit "$profile"

}

fs_state_mark_stopping() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_STATUS="stopping"
    fs_state_commit "$profile"

}

fs_state_mark_stopped() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_STATUS="stopped"
    fs_state_commit "$profile"

}

fs_state_is_running() {

    local profile="$1"

    [[ "$(fs_state_status "$profile")" == "running" ]]

}

fs_state_is_stopped() {

    local profile="$1"

    [[ "$(fs_state_status "$profile")" == "stopped" ]]

}

###############################################################################
# PID API
###############################################################################

fs_state_pid_write() {

    local profile="$1"
    local pid="$2"

    fs_state_load "$profile"

    FS_STATE_PID="$pid"

    fs_state_commit "$profile"

    printf "%s\n" "$pid" > "$(fs_profile_pid_file "$profile")"

}

fs_state_pid_read() {

    local profile="$1"
    local file

    file="$(fs_profile_pid_file "$profile")"

    if [[ -f "$file" ]]; then
        cat "$file"
        return 0
    fi

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_PID"

}

fs_state_pid_remove() {

    local profile="$1"

    rm -f -- "$(fs_profile_pid_file "$profile")"

    fs_state_load "$profile"

    FS_STATE_PID=""

    fs_state_commit "$profile"

}

fs_state_pid_exists() {

    local profile="$1"

    [[ -f "$(fs_profile_pid_file "$profile")" ]]

}

###############################################################################
# Lock API
###############################################################################

fs_state_lock_acquire() {

    local profile="$1"
    local lock_file

    lock_file="$(fs_profile_lock_file "$profile")"

    mkdir -p "$(dirname "$lock_file")"

    if [[ -e "$lock_file" ]]; then
        return 1
    fi

    (
        set -o noclobber
        : > "$lock_file"
    ) 2>/dev/null || return 1

    printf "%s\n" "$$" > "$lock_file"

    return 0

}

fs_state_lock_release() {

    local profile="$1"

    rm -f -- "$(fs_profile_lock_file "$profile")"

}

fs_state_lock_exists() {

    local profile="$1"

    [[ -f "$(fs_profile_lock_file "$profile")" ]]

}

###############################################################################
# Health API
###############################################################################

fs_state_mark_healthy() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_HEALTH="healthy"
    fs_state_commit "$profile"

}

fs_state_mark_warning() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_HEALTH="warning"
    fs_state_commit "$profile"

}

fs_state_mark_unhealthy() {

    local profile="$1"

    fs_state_load "$profile"
    FS_STATE_HEALTH="unhealthy"
    fs_state_commit "$profile"

}

fs_state_health() {

    local profile="$1"

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_HEALTH"

}

###############################################################################
# Error API
###############################################################################

fs_state_set_error() {

    local profile="$1"
    local message="$2"

    fs_state_load "$profile"

    FS_STATE_LAST_ERROR="$message"

    fs_state_commit "$profile"

}

fs_state_last_error() {

    local profile="$1"

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_LAST_ERROR"

}

fs_state_clear_error() {

    local profile="$1"

    fs_state_load "$profile"

    FS_STATE_LAST_ERROR=""

    fs_state_commit "$profile"

}

fs_state_has_error() {

    local profile="$1"

    [[ -n "$(fs_state_last_error "$profile")" ]]

}

###############################################################################
# Retry API
###############################################################################

fs_state_retry_count() {

    local profile="$1"

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_RETRY_COUNT"

}

fs_state_increment_retry() {

    local profile="$1"

    fs_state_load "$profile"

    FS_STATE_RETRY_COUNT=$((FS_STATE_RETRY_COUNT + 1))

    fs_state_commit "$profile"

}

fs_state_reset_retry() {

    local profile="$1"

    fs_state_load "$profile"

    FS_STATE_RETRY_COUNT=0

    fs_state_commit "$profile"

}

###############################################################################
# Service State API
###############################################################################

fs_state_service_write() {

    local profile="$1"
    local service_state="$2"

    fs_state_load "$profile"

    FS_STATE_SERVICE="$service_state"

    fs_state_commit "$profile"

}

fs_state_service_read() {

    local profile="$1"

    fs_state_load "$profile"

    printf "%s\n" "$FS_STATE_SERVICE"

}

###############################################################################
# Synchronization Statistics
###############################################################################

fs_state_touch_sync() {

    local profile="$1"

    fs_state_load "$profile"

    FS_STATE_LAST_SYNC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    fs_state_commit "$profile"

}

fs_state_increment_files() {

    local profile="$1"
    local count="${2:-1}"

    fs_state_load "$profile"

    FS_STATE_FILES_SYNCED=$((FS_STATE_FILES_SYNCED + count))

    fs_state_commit "$profile"

}

fs_state_increment_bytes() {

    local profile="$1"
    local bytes="${2:-0}"

    fs_state_load "$profile"

    FS_STATE_BYTES_SYNCED=$((FS_STATE_BYTES_SYNCED + bytes))

    fs_state_commit "$profile"

}

fs_state_reset_statistics() {

    local profile="$1"

    fs_state_load "$profile"

    FS_STATE_LAST_SYNC=""
    FS_STATE_FILES_SYNCED=0
    FS_STATE_BYTES_SYNCED=0

    fs_state_commit "$profile"

}

###############################################################################
# State Information
###############################################################################

fs_state_print() {

    cat <<EOF
Profile Runtime

Status       : ${FS_STATE_STATUS}
Health       : ${FS_STATE_HEALTH}
PID          : ${FS_STATE_PID}
Last Sync    : ${FS_STATE_LAST_SYNC}
Files Synced : ${FS_STATE_FILES_SYNCED}
Bytes Synced : ${FS_STATE_BYTES_SYNCED}
Retry Count  : ${FS_STATE_RETRY_COUNT}
Last Error   : ${FS_STATE_LAST_ERROR}
Service      : ${FS_STATE_SERVICE}
EOF

}

###############################################################################
# Reset State
###############################################################################

fs_state_reset() {

    local profile="$1"

    rm -f -- "$(fs_state_file "$profile")"

    fs_state_init "$profile"
    fs_state_load "$profile"

}

###############################################################################
# Destroy State
###############################################################################

fs_state_destroy() {

    local profile="$1"

    rm -rf -- "$(fs_state_directory "$profile")"
    rm -f -- "$(fs_profile_pid_file "$profile")"
    rm -f -- "$(fs_profile_lock_file "$profile")"

}

###############################################################################
# Validate State
###############################################################################

fs_state_validate() {

    local profile="$1"

    fs_state_load "$profile"

    [[ -n "$FS_STATE_STATUS" ]]
    [[ -n "$FS_STATE_HEALTH" ]]
    [[ -n "$FS_STATE_SERVICE" ]]

}

###############################################################################
# Runtime Snapshot
###############################################################################

fs_state_snapshot() {

    local profile="$1"

    fs_state_load "$profile"

    fs_state_print

}

###############################################################################
# End of File
###############################################################################