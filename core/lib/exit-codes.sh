#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/exit-codes.sh
#
# Description:
#   Defines all process exit codes used throughout FolderSynka.
#
# Responsibilities:
#   • Standardize command exit codes
#   • Provide semantic shell exit statuses
#   • Keep CLI behaviour consistent
#
###############################################################################

if [[ "${FS_EXIT_CODES_LOADED:-false}" == "true" ]]; then
    return 0
fi

FS_EXIT_CODES_LOADED=true

set -euo pipefail

###############################################################################
# POSIX Exit Codes
###############################################################################

readonly FS_EXIT_SUCCESS=0
readonly FS_EXIT_FAILURE=1
readonly FS_EXIT_USAGE=2

###############################################################################
# Generic Application Errors
###############################################################################

readonly FS_EXIT_INVALID_ARGUMENT=10
readonly FS_EXIT_INVALID_CONFIGURATION=11
readonly FS_EXIT_NOT_IMPLEMENTED=12
readonly FS_EXIT_OPERATION_CANCELLED=13

###############################################################################
# Profile Errors
###############################################################################

readonly FS_EXIT_PROFILE_EXISTS=20
readonly FS_EXIT_PROFILE_NOT_FOUND=21
readonly FS_EXIT_INVALID_PROFILE_NAME=22
readonly FS_EXIT_PROFILE_CORRUPTED=23

###############################################################################
# Filesystem Errors
###############################################################################

readonly FS_EXIT_SOURCE_NOT_FOUND=30
readonly FS_EXIT_SOURCE_NOT_READABLE=31
readonly FS_EXIT_DESTINATION_NOT_FOUND=32
readonly FS_EXIT_DESTINATION_NOT_WRITABLE=33
readonly FS_EXIT_PERMISSION_DENIED=34
readonly FS_EXIT_INVALID_PATH=35
readonly FS_EXIT_FILESYSTEM_ERROR=36

###############################################################################
# Runtime Errors
###############################################################################

readonly FS_EXIT_RUNTIME_NOT_INITIALIZED=40
readonly FS_EXIT_RUNTIME_ALREADY_INITIALIZED=41
readonly FS_EXIT_ALREADY_RUNNING=42
readonly FS_EXIT_NOT_RUNNING=43
readonly FS_EXIT_LOCK_EXISTS=44
readonly FS_EXIT_LOCK_FAILED=45

###############################################################################
# Service Errors
###############################################################################

readonly FS_EXIT_SERVICE_NOT_FOUND=50
readonly FS_EXIT_SERVICE_ALREADY_EXISTS=51
readonly FS_EXIT_SERVICE_START_FAILED=52
readonly FS_EXIT_SERVICE_STOP_FAILED=53
readonly FS_EXIT_SERVICE_RESTART_FAILED=54

###############################################################################
# Dependency Errors
###############################################################################

readonly FS_EXIT_DEPENDENCY_MISSING=60
readonly FS_EXIT_STORAGE_NOT_AVAILABLE=61
readonly FS_EXIT_UNSUPPORTED_ENVIRONMENT=62

###############################################################################
# Synchronization Errors
###############################################################################

readonly FS_EXIT_SYNC_FAILED=70
readonly FS_EXIT_RSYNC_FAILED=71
readonly FS_EXIT_WATCHER_FAILED=72
readonly FS_EXIT_IGNORE_FILE_INVALID=73

###############################################################################
# Validation Errors
###############################################################################

readonly FS_EXIT_VALIDATION_FAILED=80

###############################################################################
# Internal Errors
###############################################################################

readonly FS_EXIT_INTERNAL_ERROR=90
readonly FS_EXIT_UNKNOWN_ERROR=99

###############################################################################
# Exit Helpers
###############################################################################

fs_exit() {
    local exit_code="${1:-$FS_EXIT_FAILURE}"

    exit "$exit_code"
}

fs_exit_success() {
    fs_exit "$FS_EXIT_SUCCESS"
}

fs_exit_failure() {
    fs_exit "$FS_EXIT_FAILURE"
}

fs_exit_usage() {
    fs_exit "$FS_EXIT_USAGE"
}

fs_exit_if_failed() {
    local status="${1:-0}"
    local exit_code="${2:-$FS_EXIT_FAILURE}"

    [[ "$status" -eq 0 ]] && return 0

    fs_exit "$exit_code"
}

###############################################################################
# End of File
###############################################################################