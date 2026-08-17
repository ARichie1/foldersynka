#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/utils/validation.sh
#
# Description:
#   Primitive validation library for FolderSynka.
#
# Responsibilities:
#   • Validate profiles
#   • Validate filesystem objects
#   • Validate runtime state
#   • Validate services
#   • Validate dependencies
#   • Validate execution environment
#
# Command-specific validation belongs outside this module.
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/constants.sh"
source "${FS_HOME}/core/lib/error-codes.sh"
source "${FS_HOME}/core/lib/errors.sh"
source "${FS_HOME}/core/lib/environment.sh"
source "${FS_HOME}/core/lib/validation-context.sh"

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/utils/filesystem.sh"

###############################################################################
# Profile Validation
###############################################################################

fs_validate_profile_name() {
    local profile="$1"

    fs_validation_reset

    if [[ -z "$profile" ]]; then
        fs_validation_fail \
            "$FS_ERR_INVALID_PROFILE_NAME" \
            "profile"
        return 1
    fi

    if [[ ${#profile} -gt "$FS_PROFILE_NAME_MAX_LENGTH" ]]; then
        fs_validation_fail \
            "$FS_ERR_INVALID_PROFILE_NAME" \
            "profile"
        return 1
    fi

    if [[ ! "$profile" =~ $FS_PROFILE_NAME_REGEX ]]; then
        fs_validation_fail \
            "$FS_ERR_INVALID_PROFILE_NAME" \
            "profile"
        return 1
    fi

    fs_validation_success
}

fs_validate_profile_exists() {
    local profile="$1"
    local profile_file

    fs_validation_reset

    profile_file="$(fs_profile_config_file "$profile")"

    if [[ ! -f "$profile_file" ]]; then
        fs_validation_fail \
            "$FS_ERR_PROFILE_NOT_FOUND" \
            "profile"
        return 1
    fi

    fs_validation_success
}

fs_validate_profile_missing() {
    local profile="$1"
    local profile_file

    fs_validation_reset

    profile_file="$(fs_profile_config_file "$profile")"

    if [[ -f "$profile_file" ]]; then
        fs_validation_fail \
            "$FS_ERR_PROFILE_EXISTS" \
            "profile"
        return 1
    fi

    fs_validation_success
}

fs_validate_profile_configuration() {
    local profile="$1"

    fs_validation_reset

    if ! fs_profile_load "$profile"; then
        fs_validation_fail \
            "$FS_ERR_PROFILE_CORRUPTED" \
            "profile"
        return 1
    fi

    fs_validation_success
}

###############################################################################
# Source Validation
###############################################################################

fs_validate_source() {
    local source="$1"

    fs_validation_reset

    if ! fs_exists "$source"; then
        fs_validation_fail \
            "$FS_ERR_SOURCE_NOT_FOUND" \
            "source"
        return 1
    fi

    if ! fs_directory_exists "$source"; then
        fs_validation_fail \
            "$FS_ERR_SOURCE_NOT_DIRECTORY" \
            "source"
        return 1
    fi

    if ! fs_is_readable "$source"; then
        fs_validation_fail \
            "$FS_ERR_SOURCE_NOT_READABLE" \
            "source"
        return 1
    fi

    fs_validation_success
}

###############################################################################
# Destination Validation
###############################################################################

fs_validate_destination() {
    local destination="$1"
    local parent

    fs_validation_reset

    if ! fs_require_safe_path "$destination"; then
        fs_validation_fail \
            "$FS_ERR_DESTINATION_UNSAFE" \
            "destination"
        return 1
    fi

    if fs_directory_exists "$destination"; then
        if ! fs_is_writable "$destination"; then
            fs_validation_fail \
                "$FS_ERR_DESTINATION_NOT_WRITABLE" \
                "destination"
            return 1
        fi

        fs_validation_success
        return 0
    fi

    parent="$(dirname "$destination")"

    if ! fs_directory_exists "$parent"; then
        fs_validation_fail \
            "$FS_ERR_DESTINATION_PARENT_NOT_FOUND" \
            "destination"
        return 1
    fi

    if ! fs_is_writable "$parent"; then
        fs_validation_fail \
            "$FS_ERR_DESTINATION_NOT_WRITABLE" \
            "destination"
        return 1
    fi

    fs_validation_success
}

###############################################################################
# Ignore File Validation
###############################################################################

fs_validate_ignore_file() {
    local source="$1"
    local ignore_file

    fs_validation_reset

    ignore_file="${source}/${FS_IGNORE_FILE}"

    if [[ ! -e "$ignore_file" ]]; then
        fs_validation_success
        return 0
    fi

    if [[ ! -f "$ignore_file" ]]; then
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_INVALID" \
            "ignore"
        return 1
    fi

    if ! fs_is_readable "$ignore_file"; then
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_NOT_READABLE" \
            "ignore"
        return 1
    fi

    fs_validation_success
}

###############################################################################
# Runtime Validation
###############################################################################

fs_validate_runtime() {
    [[ -d "$FS_RUNTIME_DIR" ]] &&
    [[ -d "$FS_CONFIG_DIR" ]] &&
    [[ -d "$FS_STATE_DIR" ]] &&
    [[ -d "$FS_LOG_DIR" ]] &&
    [[ -d "$FS_PID_DIR" ]] &&
    [[ -d "$FS_LOCK_DIR" ]] &&
    [[ -d "$FS_CACHE_DIR" ]] &&
    [[ -d "$FS_SERVICE_DIR" ]]
}

fs_validate_runtime_directory() {
    local directory="$1"

    [[ -d "$directory" ]]
}

###############################################################################
# Service Validation
###############################################################################

fs_validate_termux_services() {
    command -v sv >/dev/null 2>&1
}

fs_validate_service_exists() {
    local profile="$1"
    local service

    service="$(fs_termux_service_dir "$profile")"

    [[ -d "$service" ]]
}

fs_validate_service_running() {
    local profile="$1"

    sv status "$(fs_service_name "$profile")" >/dev/null 2>&1
}

###############################################################################
# Dependency Validation
###############################################################################

fs_validate_command() {
    command -v "$1" >/dev/null 2>&1
}

fs_validate_rsync() {
    fs_validate_command rsync
}

fs_validate_inotify() {
    fs_validate_command inotifywait
}

fs_validate_termux_api() {
    fs_validate_command termux-toast
}

fs_validate_sv() {
    fs_validate_command sv
}

###############################################################################
# Storage Validation
###############################################################################

fs_validate_storage() {
    [[ -d "/storage/emulated/0" ]]
}

fs_validate_storage_permission() {
    [[ -d "$HOME/storage" ]]
}

fs_validate_source_directory() {
    local directory="$1"

    [[ -d "$directory" ]]
}

fs_validate_destination_directory() {
    local directory="$1"

    [[ -d "$directory" ]]
}

fs_validate_writable_directory() {
    local directory="$1"

    [[ -d "$directory" ]] &&
    [[ -w "$directory" ]]
}

###############################################################################
# Environment Validation
###############################################################################

fs_validate_termux_environment() {
    [[ -n "${PREFIX:-}" ]]
}

fs_validate_home() {
    [[ -n "${HOME:-}" ]]
}

fs_validate_prefix() {
    [[ -d "${PREFIX:-}" ]]
}

fs_validate_tmpdir() {
    [[ -d "${TMPDIR:-/tmp}" ]]
}

fs_validate_path_environment() {
    [[ -n "${PATH:-}" ]]
}

###############################################################################
# Composite Validation
###############################################################################

fs_validate_environment() {
    fs_validate_termux_environment &&
    fs_validate_home &&
    fs_validate_prefix &&
    fs_validate_tmpdir &&
    fs_validate_path_environment
}

fs_validate_system() {
    fs_validate_environment &&
    fs_validate_storage &&
    fs_validate_storage_permission &&
    fs_validate_rsync &&
    fs_validate_inotify &&
    fs_validate_sv &&
    fs_validate_termux_services
}

###############################################################################
# End
###############################################################################