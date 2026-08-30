#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/utils/logger.sh
#
# Description:
#   Central logging utility.
#
# Responsibilities:
#   • Generate timestamps
#   • Write log messages
#   • Display terminal messages
#   • Manage profile log files
#   • Read and clear logs
#
# Public logging API:
#
#   fs_log_debug "message"
#   fs_log_info "message"
#   fs_log_warn "message"
#   fs_log_error "message"
#   fs_log_success "message"
#
###############################################################################

set -euo pipefail

if [[ "${FS_LOGGER_LOADED:-false}" == "true" ]]; then
    return 0
fi

FS_LOGGER_LOADED=true

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/utils/terminal.sh"

###############################################################################
# Log Levels
###############################################################################

readonly FS_LOG_DEBUG="DEBUG"
readonly FS_LOG_INFO="INFO"
readonly FS_LOG_WARN="WARN"
readonly FS_LOG_ERROR="ERROR"
readonly FS_LOG_SUCCESS="SUCCESS"

###############################################################################
# Timestamp
###############################################################################

fs_log_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

###############################################################################
# Current Log File
###############################################################################

#
# Uses the currently loaded profile when available.
# Falls back to the main FolderSynka log for system-level messages.
#
fs_log_file() {
    local profile="${FS_PROFILE_NAME:-}"

    if [[ -n "$profile" ]]; then
        fs_profile_log_file "$profile"
        return 0
    fi

    printf "%s\n" "$FS_MAIN_LOG"
}

###############################################################################
# Internal Logger
###############################################################################

_fs_log() {
    local level="$1"
    shift

    local message="$*"
    local logfile

    logfile="$(fs_log_file)"

    mkdir -p "$(dirname "$logfile")"

    printf "%s [%s] %s\n" \
        "$(fs_log_timestamp)" \
        "$level" \
        "$message" >> "$logfile"
}

###############################################################################
# Debug
###############################################################################

fs_log_debug() {
    _fs_log "$FS_LOG_DEBUG" "$@"
}

###############################################################################
# Info
###############################################################################

fs_log_info() {
    fs_print_info "$@"
    _fs_log "$FS_LOG_INFO" "$@"
}

###############################################################################
# Warning
###############################################################################

fs_log_warn() {
    fs_print_warning "$@"
    _fs_log "$FS_LOG_WARN" "$@"
}

###############################################################################
# Error
###############################################################################

fs_log_error() {
    fs_print_error "$@"
    _fs_log "$FS_LOG_ERROR" "$@"
}

###############################################################################
# Success
###############################################################################

fs_log_success() {
    fs_print_success "$@"
    _fs_log "$FS_LOG_SUCCESS" "$@"
}

###############################################################################
# Read Log
###############################################################################

fs_log_tail() {
    local lines="${1:-20}"
    local logfile

    logfile="$(fs_log_file)"

    [[ -f "$logfile" ]] || return 0

    tail -n "$lines" "$logfile"
}

###############################################################################
# Clear Log
###############################################################################

fs_log_clear() {
    local logfile

    logfile="$(fs_log_file)"

    mkdir -p "$(dirname "$logfile")"
    : > "$logfile"
}

###############################################################################
# Log Exists
###############################################################################

fs_log_exists() {
    local logfile

    logfile="$(fs_log_file)"

    [[ -f "$logfile" ]]
}

###############################################################################
# Log Size
###############################################################################

fs_log_size() {
    local logfile

    logfile="$(fs_log_file)"

    if [[ -f "$logfile" ]]; then
        wc -c < "$logfile"
    else
        printf "0\n"
    fi
}

###############################################################################
# Rotate Log
###############################################################################

fs_log_rotate() {
    local logfile
    local rotated

    logfile="$(fs_log_file)"

    [[ -f "$logfile" ]] || return 0

    rotated="${logfile}.$(date -u +%Y%m%d-%H%M%S)"

    mv "$logfile" "$rotated"
}

###############################################################################
# End
###############################################################################