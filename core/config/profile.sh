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

    local config
    local timestamp

    config="$(fs_profile_config_file "$profile")"

    if fs_profile_exists "$profile"; then
        printf 'Profile already exists: %s\n' "$profile"
        return 1
    fi

    timestamp="$(date -u +"${FS_LOG_TIMESTAMP_FORMAT}")"

    cat > "$config" <<EOF
###############################################################################
# FolderSynka Profile Configuration
###############################################################################

CONFIG_VERSION="${FS_DEFAULT_CONFIG_VERSION}"

CREATED_AT="${timestamp}"

UPDATED_AT="${timestamp}"

PROFILE_NAME="${profile}"

SOURCE="${source}"

DESTINATION="${destination}"

WATCH=${FS_DEFAULT_WATCH}

DELETE=${FS_DEFAULT_DELETE}

FOLLOW_SYMLINKS=${FS_DEFAULT_FOLLOW_SYMLINKS}

CHECKSUM=${FS_DEFAULT_CHECKSUM}

COMPRESS=${FS_DEFAULT_COMPRESS}

IGNORE_FILE="${FS_IGNORE_FILE}"

AUTO_START=${FS_DEFAULT_AUTO_START}

SERVICE_NAME="$(fs_service_name "$profile")"

LOG_LEVEL="${FS_DEFAULT_LOG_LEVEL}"

LOG_FILE="$(fs_profile_log_file "$profile")"
EOF
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

    config="$(fs_profile_config_file "$profile")"

    if [[ ! -f "$config" ]]; then
        printf 'Profile not found: %s\n' "$profile"
        return 1
    fi

    # shellcheck disable=SC1090
    source "$config"

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

    fs_profile_load "$profile"

    case "$key" in
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
        PROFILE_NAME|SOURCE|DESTINATION|WATCH|DELETE|FOLLOW_SYMLINKS|CHECKSUM|COMPRESS|IGNORE_FILE|AUTO_START|SERVICE_NAME|LOG_LEVEL|LOG_FILE)
            ;;
        *)
            printf 'Unknown or immutable profile property: %s\n' "$key"
            return 1
            ;;
    esac

    timestamp="$(date -u +"${FS_LOG_TIMESTAMP_FORMAT}")"

    sed -i \
        "s|^${key}=.*|${key}=\"${value}\"|" \
        "$config"

    sed -i \
        "s|^UPDATED_AT=.*|UPDATED_AT=\"${timestamp}\"|" \
        "$config"
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

    [[ -n "$source" ]]
    [[ -n "$destination" ]]
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