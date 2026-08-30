#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/engine/watcher.sh
#
# Description:
#   Filesystem watcher engine.
#
# Responsibilities:
#   • Watch source directories
#   • Normalize filesystem events
#   • Filter ignored events
#   • Debounce event bursts
#   • Notify the synchronization engine
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"

source "${FS_HOME}/core/utils/logger.sh"
source "${FS_HOME}/core/utils/validation.sh"

###############################################################################
# Globals
###############################################################################

FS_WATCHER_PID=""
FS_WATCHER_COMMAND=()

fs_watcher_pid_file() {
    local profile="$1"

    printf '%s/%s.watcher.pid\n' "$FS_CACHE_DIR" "$profile"
}

###############################################################################
# Availability
###############################################################################

fs_watcher_available() {
    fs_validate_inotify
}

###############################################################################
# Build Watch Command
###############################################################################

fs_watcher_build_command() {
    local source="$1"

    FS_WATCHER_COMMAND=(
        inotifywait
        --monitor
        --recursive
        --quiet
        --format '%w|%f|%e'
        --event create
        --event modify
        --event delete
        --event move
        "$source"
    )
}

###############################################################################
# Normalize Event
###############################################################################

fs_watcher_normalize_event() {
    local event="$1"

    case "$event" in
        *MOVED_FROM*|*MOVED_TO*|*MOVE*)
            printf '%s\n' "MOVED"
            ;;

        *CREATE*)
            printf '%s\n' "CREATED"
            ;;

        *MODIFY*|*CLOSE_WRITE*)
            printf '%s\n' "UPDATED"
            ;;

        *DELETE*)
            printf '%s\n' "DELETED"
            ;;

        *)
            printf '%s\n' "UNKNOWN"
            ;;
    esac
}

###############################################################################
# Ignore Event
###############################################################################

fs_watcher_ignore_event() {
    local file="$1"

    case "$file" in
        *.swp|*.swx|*~)
            return 0
            ;;

        .DS_Store|Thumbs.db)
            return 0
            ;;

        "$FS_PROFILE_IGNORE_FILE")
            return 0
            ;;

        *)
            return 1
            ;;
    esac
}

###############################################################################
# Watch Loop
###############################################################################

fs_watcher_loop() {
    local profile="$1"
    local callback="$2"
    local pid_file

    pid_file="$(fs_watcher_pid_file "$profile")"
    printf '%s\n' "$BASHPID" > "$pid_file"

    trap 'rm -f -- "$pid_file"; exit 0' TERM INT EXIT

    while IFS='|' read -r directory file raw_event
    do
        local event

        event="$(fs_watcher_normalize_event "$raw_event")"

        [[ "$event" == "UNKNOWN" ]] && continue

        fs_watcher_ignore_event "$file" && continue

        sleep "${FS_DEFAULT_DEBOUNCE}"

        "$callback" \
            "$directory" \
            "$file" \
            "$event"

    done < <("${FS_WATCHER_COMMAND[@]}")
}

###############################################################################
# Start Watcher
###############################################################################

fs_watcher_start() {
    local profile="$1"
    local source="$2"
    local callback="$3"

    fs_watcher_available || return 1
    fs_validate_source "$source" || return 1

    if fs_watcher_running; then
        fs_log_warn \
                        "Watcher is already running."

        return 1
    fi

    fs_watcher_build_command "$source"

    fs_log_info \
                "Starting filesystem watcher: ${source}"

    local pid_file
    pid_file="$(fs_watcher_pid_file "$profile")"
    rm -f -- "$pid_file"

    fs_watcher_loop "$profile" "$callback" &

    for _ in {1..20}; do
        if [[ -s "$pid_file" ]]; then
            FS_WATCHER_PID="$(<"$pid_file")"
            break
        fi
        sleep 0.05
    done

    [[ -n "$FS_WATCHER_PID" ]] || return 1

    fs_log_debug \
                "Watcher started with PID ${FS_WATCHER_PID}."
}

###############################################################################
# Stop Watcher
###############################################################################

fs_watcher_stop() {
    local profile="${1:-system}"

    if [[ -z "$FS_WATCHER_PID" ]]; then
        return 0
    fi

    if kill -0 "$FS_WATCHER_PID" 2>/dev/null; then
        fs_log_debug \
                        "Stopping watcher PID ${FS_WATCHER_PID}."

        kill -TERM "$FS_WATCHER_PID" 2>/dev/null || true
    fi

    rm -f -- "$(fs_watcher_pid_file "$profile")"
    FS_WATCHER_PID=""
}

###############################################################################
# Restart Watcher
###############################################################################

fs_watcher_restart() {
    local profile="$1"
    local source="$2"
    local callback="$3"

    fs_watcher_stop "$profile"

    fs_watcher_start \
        "$profile" \
        "$source" \
        "$callback"
}

###############################################################################
# Watch Profile
###############################################################################

fs_watcher_profile() {
    local profile="$1"
    local callback="$2"

    fs_profile_load "$profile"

    fs_watcher_start \
        "$profile" \
        "$FS_PROFILE_SOURCE" \
        "$callback"
}

###############################################################################
# Status
###############################################################################

fs_watcher_running() {
    [[ -n "$FS_WATCHER_PID" ]] &&
    kill -0 "$FS_WATCHER_PID" 2>/dev/null
}

###############################################################################
# PID
###############################################################################

fs_watcher_pid() {
    printf '%s\n' "$FS_WATCHER_PID"
}

###############################################################################
# End of File
###############################################################################