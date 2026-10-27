#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/config/profile.sh
#
# Description:
#   Canonical profile management API.
#
# Responsibilities:
#   • Create profiles
#   • Load profiles
#   • Update profiles
#   • Delete profiles
#   • List profiles
#   • Read profile properties
#   • Write profile properties
#   • Validate loaded profile data
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/constants.sh"
source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/config/defaults.sh"
source "${FS_HOME}/core/utils/filesystem.sh"

###############################################################################
# Profile Existence
###############################################################################

fs_profile_exists() {
    local profile="$1"

    [[ -f "$(fs_profile_config_file "$profile")" ]]
}

###############################################################################
# Create Profile
###############################################################################

fs_profile_create() {
    local profile="$1"
    local source="$2"
    local destination="$3"

    fs_profile_validate_name "$profile" || return 1
    fs_validate_path_pair "$source" "$destination" || return 1
    source=$(fs_normalize_path "$source") || return 1
    destination=$(fs_normalize_path "$destination") || return 1

    local config
    local timestamp

    config="$(fs_profile_config_file "$profile")"

    mkdir -p "$FS_CONFIG_DIR"

    if fs_profile_exists "$profile"; then
        printf 'Profile already exists: %s\n' "$profile"
        return 1
    fi

    timestamp="$(date -u +"${FS_LOG_TIMESTAMP_FORMAT}")"

    local temporary
    temporary=$(mktemp "${config}.XXXXXX") || return 1
    {
        fs_data_assignment CONFIG_VERSION "$FS_DEFAULT_CONFIG_VERSION"
        fs_data_assignment CREATED_AT "$timestamp"
        fs_data_assignment UPDATED_AT "$timestamp"
        fs_data_assignment PROFILE_NAME "$profile"
        fs_data_assignment SOURCE "$source"
        fs_data_assignment DESTINATION "$destination"
        fs_data_assignment MODE "copy"
        fs_data_assignment WATCH "$FS_DEFAULT_WATCH"
        fs_data_assignment DELETE "$FS_DEFAULT_DELETE"
        fs_data_assignment FOLLOW_SYMLINKS "$FS_DEFAULT_FOLLOW_SYMLINKS"
        fs_data_assignment CHECKSUM "$FS_DEFAULT_CHECKSUM"
        fs_data_assignment COMPRESS "$FS_DEFAULT_COMPRESS"
        fs_data_assignment IGNORE_FILE "$FS_IGNORE_FILE"
        fs_data_assignment AUTO_START "$FS_DEFAULT_AUTO_START"
        fs_data_assignment SERVICE_NAME "$(fs_service_name "$profile")"
        fs_data_assignment LOG_LEVEL "$FS_DEFAULT_LOG_LEVEL"
        fs_data_assignment LOG_FILE "$(fs_profile_log_file "$profile")"
    } > "$temporary" || { rm -f -- "$temporary"; return 1; }
    ln -- "$temporary" "$config" || { rm -f -- "$temporary"; return 1; }
    rm -f -- "$temporary"

}

###############################################################################
# Update Profile
###############################################################################

fs_profile_update() {
    local profile="$1"

    shift

    while [[ $# -gt 1 ]]; do
        fs_profile_set "$profile" "$1" "$2"
        shift 2
    done
}

###############################################################################
# Load Profile
###############################################################################

fs_profile_load() {
    local profile="$1"
    local config

    fs_profile_validate_name "$profile" || return 1
    config="$(fs_profile_config_file "$profile")"

    if [[ ! -f "$config" ]]; then
        printf 'Profile not found: %s\n' "$profile"
        return 1
    fi

    local CONFIG_VERSION= CREATED_AT= UPDATED_AT= PROFILE_NAME= SOURCE= DESTINATION=
    local WATCH= DELETE= FOLLOW_SYMLINKS= CHECKSUM= COMPRESS= IGNORE_FILE=
    local AUTO_START= SERVICE_NAME= LOG_LEVEL= LOG_FILE= MODE=
    fs_data_read "$config" "CONFIG_VERSION CREATED_AT UPDATED_AT PROFILE_NAME SOURCE DESTINATION MODE WATCH DELETE FOLLOW_SYMLINKS CHECKSUM COMPRESS IGNORE_FILE AUTO_START SERVICE_NAME LOG_LEVEL LOG_FILE" || return 1
    [[ "$CONFIG_VERSION" == "$FS_DEFAULT_CONFIG_VERSION" && "$PROFILE_NAME" == "$profile" ]] || return 1
    local flag
    for flag in WATCH DELETE FOLLOW_SYMLINKS CHECKSUM COMPRESS AUTO_START; do
        [[ "${!flag}" == true || "${!flag}" == false ]] || return 1
    done
    [[ -n "$SERVICE_NAME" && -n "$LOG_FILE" && -n "$IGNORE_FILE" ]] || return 1
    [[ "$LOG_LEVEL" =~ ^(debug|info|warn|warning|error)$ ]] || return 1
    if [[ -z "$MODE" ]]; then
        MODE=copy
        [[ "$DELETE" != true ]] || MODE=mirror
    fi
    [[ "$MODE" =~ ^(copy|mirror|bidirectional)$ ]] || return 1
    fs_validate_path_pair "$SOURCE" "$DESTINATION" || return 1
    export FS_PROFILE_MODE="$MODE"

    export FS_PROFILE_NAME="$PROFILE_NAME"
    export FS_PROFILE_SOURCE="$SOURCE"
    export FS_PROFILE_DESTINATION="$DESTINATION"
    export FS_PROFILE_WATCH="$WATCH"
    export FS_PROFILE_DELETE="$DELETE"
    export FS_PROFILE_FOLLOW_SYMLINKS="$FOLLOW_SYMLINKS"
    export FS_PROFILE_CHECKSUM="$CHECKSUM"
    export FS_PROFILE_COMPRESS="$COMPRESS"
    export FS_PROFILE_IGNORE_FILE="$IGNORE_FILE"
    export FS_PROFILE_AUTO_START="$AUTO_START"
    export FS_PROFILE_SERVICE_NAME="$SERVICE_NAME"
    export FS_PROFILE_LOG_LEVEL="$LOG_LEVEL"
    export FS_PROFILE_LOG_FILE="$LOG_FILE"
}

###############################################################################
# Reload Current Profile
###############################################################################

fs_profile_reload() {
    [[ -n "${FS_PROFILE_NAME:-}" ]] || return 1

    fs_profile_load "$FS_PROFILE_NAME"
}

###############################################################################
# Delete Profile
###############################################################################

fs_profile_delete() {
    local profile="$1"

    rm -f "$(fs_profile_config_file "$profile")"
}

###############################################################################
# List Profiles
###############################################################################

fs_profile_list() {
    [[ -d "$FS_CONFIG_DIR" ]] || return 0

    local file

    for file in "$FS_CONFIG_DIR"/*.conf; do
        [[ -e "$file" ]] || continue

        basename "$file" "$FS_PROFILE_CONFIG_EXTENSION"
    done
}

###############################################################################
# Count Profiles
###############################################################################

fs_profile_count() {
    fs_profile_list | wc -l
}

###############################################################################
# Get Property
###############################################################################

fs_profile_get() {
    local profile="$1"
    local key="$2"

    fs_profile_load "$profile" || return 1

    case "$key" in
        MODE)
            printf '%s\n' "$FS_PROFILE_MODE"
            ;;
        PROFILE_NAME)
            printf '%s\n' "$FS_PROFILE_NAME"
            ;;
        SOURCE)
            printf '%s\n' "$FS_PROFILE_SOURCE"
            ;;
        DESTINATION)
            printf '%s\n' "$FS_PROFILE_DESTINATION"
            ;;
        WATCH)
            printf '%s\n' "$FS_PROFILE_WATCH"
            ;;
        DELETE)
            printf '%s\n' "$FS_PROFILE_DELETE"
            ;;
        FOLLOW_SYMLINKS)
            printf '%s\n' "$FS_PROFILE_FOLLOW_SYMLINKS"
            ;;
        CHECKSUM)
            printf '%s\n' "$FS_PROFILE_CHECKSUM"
            ;;
        COMPRESS)
            printf '%s\n' "$FS_PROFILE_COMPRESS"
            ;;
        IGNORE_FILE)
            printf '%s\n' "$FS_PROFILE_IGNORE_FILE"
            ;;
        AUTO_START)
            printf '%s\n' "$FS_PROFILE_AUTO_START"
            ;;
        SERVICE_NAME)
            printf '%s\n' "$FS_PROFILE_SERVICE_NAME"
            ;;
        LOG_LEVEL)
            printf '%s\n' "$FS_PROFILE_LOG_LEVEL"
            ;;
        LOG_FILE)
            printf '%s\n' "$FS_PROFILE_LOG_FILE"
            ;;
        *)
            printf 'Unknown profile property: %s\n' "$key"
            return 1
            ;;
    esac
}

###############################################################################
# Set Property
###############################################################################

fs_profile_set() {
    local profile="$1"
    local key="$2"
    local value="$3"

    local config
    local timestamp

    config="$(fs_profile_config_file "$profile")"

    [[ -f "$config" ]] || return 1

    case "$key" in
        MODE|PROFILE_NAME|SOURCE|DESTINATION|WATCH|DELETE|FOLLOW_SYMLINKS|CHECKSUM|COMPRESS|IGNORE_FILE|AUTO_START|SERVICE_NAME|LOG_LEVEL|LOG_FILE)
            ;;
        *)
            printf 'Unknown or immutable profile property: %s\n' "$key"
            return 1
            ;;
    esac

    case "$key" in
        MODE) [[ "$value" =~ ^(copy|mirror|bidirectional)$ ]] || return 1 ;;
        WATCH|DELETE|FOLLOW_SYMLINKS|CHECKSUM|COMPRESS|AUTO_START)
            [[ "$value" == true || "$value" == false ]] || return 1 ;;
        PROFILE_NAME) [[ "$value" == "$profile" ]] || return 1 ;;
        LOG_LEVEL) [[ "$value" =~ ^(debug|info|warn|warning|error)$ ]] || return 1 ;;
        IGNORE_FILE|SERVICE_NAME|LOG_FILE) [[ -n "$value" ]] || return 1 ;;
    esac
    fs_profile_load "$profile" || return 1
    if [[ "$key" == SOURCE ]]; then
        fs_validate_path_pair "$value" "$FS_PROFILE_DESTINATION" || return 1
    elif [[ "$key" == DESTINATION ]]; then
        fs_validate_path_pair "$FS_PROFILE_SOURCE" "$value" || return 1
    fi
    timestamp="$(date -u +"${FS_LOG_TIMESTAMP_FORMAT}")"
    local temporary line
    temporary=$(mktemp "${config}.XXXXXX") || return 1
    # Validated input uses one assignment per logical value. Re-serialize all
    # fields so multiline values never become line-oriented replacement syntax.
    (
        local CONFIG_VERSION= CREATED_AT= UPDATED_AT= PROFILE_NAME= SOURCE= DESTINATION=
        local MODE= WATCH= DELETE= FOLLOW_SYMLINKS= CHECKSUM= COMPRESS= IGNORE_FILE=
        local AUTO_START= SERVICE_NAME= LOG_LEVEL= LOG_FILE=
        fs_data_read "$config" "CONFIG_VERSION CREATED_AT UPDATED_AT PROFILE_NAME SOURCE DESTINATION MODE WATCH DELETE FOLLOW_SYMLINKS CHECKSUM COMPRESS IGNORE_FILE AUTO_START SERVICE_NAME LOG_LEVEL LOG_FILE" || exit 1
        printf -v "$key" '%s' "$value"
        UPDATED_AT=$timestamp
        for line in CONFIG_VERSION CREATED_AT UPDATED_AT PROFILE_NAME SOURCE DESTINATION WATCH DELETE FOLLOW_SYMLINKS CHECKSUM COMPRESS IGNORE_FILE AUTO_START SERVICE_NAME LOG_LEVEL LOG_FILE; do
            fs_data_assignment "$line" "${!line}"
        done
        [[ -z "$MODE" ]] || fs_data_assignment MODE "$MODE"
    ) > "$temporary" || { rm -f -- "$temporary"; return 1; }
    mv -f -- "$temporary" "$config"

}

###############################################################################
# Validate Profile Name
###############################################################################

fs_profile_validate_name() {
    local profile="$1"

    [[ -n "$profile" ]] || return 1
    [[ ${#profile} -le "$FS_PROFILE_NAME_MAX_LENGTH" ]] || return 1
    [[ "$profile" =~ $FS_PROFILE_NAME_REGEX ]]
}

###############################################################################
# Validate Profile Paths
###############################################################################

fs_profile_validate_paths() {
    local source="$1"
    local destination="$2"

    fs_validate_path_pair "$source" "$destination"
}

###############################################################################
# Validate Loaded Profile
###############################################################################

fs_profile_is_valid() {
    local profile="$1"

    fs_profile_load "$profile" || return 1

    [[ -n "${FS_PROFILE_NAME:-}" ]]
    [[ -n "${FS_PROFILE_SOURCE:-}" ]]
    [[ -n "${FS_PROFILE_DESTINATION:-}" ]]
}

###############################################################################
# End of File
###############################################################################
