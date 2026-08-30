#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/config/paths.sh
#
# Description:
#   Defines filesystem locations used by FolderSynka.
###############################################################################

if [[ "${FS_PATHS_LOADED:-false}" == "true" ]]; then
    return 0
fi

FS_PATHS_LOADED=true

set -euo pipefail

###############################################################################
# Bootstrap
###############################################################################

if [[ -z "${FS_HOME:-}" ]]; then
    FS_HOME="${PREFIX}/share/foldersynka"
fi

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/constants.sh"

###############################################################################
# Installation Paths
###############################################################################

readonly FS_BIN_DIR="${PREFIX}/bin"
readonly FS_CORE_DIR="${FS_HOME}/core"
readonly FS_TEMPLATE_DIR="${FS_CORE_DIR}/templates"
readonly FS_VERSION_FILE="${FS_HOME}/VERSION"

###############################################################################
# Runtime Paths
###############################################################################

readonly FS_RUNTIME_DIR="${HOME}/.foldersynka"
readonly FS_CONFIG_DIR="${FS_RUNTIME_DIR}/configs"
readonly FS_STATE_DIR="${FS_RUNTIME_DIR}/state"
readonly FS_LOG_DIR="${FS_RUNTIME_DIR}/logs"
readonly FS_PID_DIR="${FS_RUNTIME_DIR}/pids"
readonly FS_LOCK_DIR="${FS_RUNTIME_DIR}/locks"
readonly FS_CACHE_DIR="${FS_RUNTIME_DIR}/cache"
readonly FS_SERVICE_DIR="${FS_RUNTIME_DIR}/services"

###############################################################################
# Template Paths
###############################################################################

readonly FS_DEFAULT_IGNORE_TEMPLATE="${FS_TEMPLATE_DIR}/${FS_IGNORE_FILE}"

###############################################################################
# Termux Service Paths
###############################################################################

readonly FS_TERMUX_SERVICE_DIR="${PREFIX}/var/service"

###############################################################################
# Runtime Files
###############################################################################

readonly FS_MAIN_LOG="${FS_LOG_DIR}/foldersynka.log"

###############################################################################
# Directory Helpers
###############################################################################

fs_runtime_dir() {
    printf '%s\n' "$FS_RUNTIME_DIR"
}

fs_config_dir() {
    printf '%s\n' "$FS_CONFIG_DIR"
}

fs_state_dir() {
    printf '%s\n' "$FS_STATE_DIR"
}

fs_log_dir() {
    printf '%s\n' "$FS_LOG_DIR"
}

fs_pid_dir() {
    printf '%s\n' "$FS_PID_DIR"
}

fs_lock_dir() {
    printf '%s\n' "$FS_LOCK_DIR"
}

fs_cache_dir() {
    printf '%s\n' "$FS_CACHE_DIR"
}

fs_service_dir() {
    printf '%s\n' "$FS_SERVICE_DIR"
}

###############################################################################
# Profile Paths
###############################################################################

fs_profile_config_file() {
    local profile="$1"

    printf '%s/%s%s\n' \
        "$FS_CONFIG_DIR" \
        "$profile" \
        "$FS_PROFILE_CONFIG_EXTENSION"
}

fs_profile_log_file() {
    local profile="$1"

    printf '%s/%s.log\n' \
        "$FS_LOG_DIR" \
        "$profile"
}

fs_profile_pid_file() {
    local profile="$1"

    printf '%s/%s.pid\n' \
        "$FS_PID_DIR" \
        "$profile"
}

fs_profile_lock_file() {
    local profile="$1"

    printf '%s/%s.lock\n' \
        "$FS_LOCK_DIR" \
        "$profile"
}

###############################################################################
# State Paths
###############################################################################

fs_profile_state_dir() {
    local profile="$1"

    printf '%s/%s\n' \
        "$FS_STATE_DIR" \
        "$profile"
}

fs_profile_runtime_file() {
    local profile="$1"

    printf '%s/%s\n' \
        "$(fs_profile_state_dir "$profile")" \
        "$FS_RUNTIME_FILE"
}

###############################################################################
# Service Paths
###############################################################################

fs_service_name() {
    local profile="$1"

    printf '%s-%s\n' \
        "$FS_SERVICE_PREFIX" \
        "$profile"
}

fs_termux_service_dir() {
    local profile="$1"

    printf '%s/%s\n' \
        "$FS_TERMUX_SERVICE_DIR" \
        "$(fs_service_name "$profile")"
}

###############################################################################
# End of File
###############################################################################