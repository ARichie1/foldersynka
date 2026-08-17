#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/ignore.sh
#
# Description:
#   CLI interface for .foldersynkaignore management.
#
# Responsibilities:
#   • Parse ignore command arguments
#   • Resolve profiles
#   • Dispatch ignore operations
#   • Present user-facing output
#
# Ignore file operations are implemented by:
#   core/config/ignore.sh
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/ignore.sh"

source "${FS_HOME}/core/lib/errors.sh"

source "${FS_HOME}/core/utils/logger.sh"

###############################################################################
# Help
###############################################################################

fs_ignore_help() {

    cat <<EOF

FolderSynka Ignore

Manage the .foldersynkaignore file for a sync profile.

USAGE

    foldersynka ignore <profile> <command> [pattern]

COMMANDS

    init
        Create the .foldersynkaignore file if it does not exist.

    list
        List configured ignore patterns.

    show
        Display the complete ignore file.

    add <pattern>
        Add an ignore pattern.

    remove <pattern>
        Remove an ignore pattern.

    reset
        Restore the canonical ignore template.

    info
        Show ignore file information.

EXAMPLES

    foldersynka ignore my-app init

    foldersynka ignore my-app list

    foldersynka ignore my-app show

    foldersynka ignore my-app add node_modules/

    foldersynka ignore my-app remove node_modules/

    foldersynka ignore my-app reset

    foldersynka ignore my-app info

EOF

}

###############################################################################
# Profile Validation
###############################################################################

fs_ignore_require_profile() {

    local profile="$1"

    if [[ -z "$profile" ]]; then
        fs_log_error "Profile is required."
        return 1
    fi

    if ! fs_profile_exists "$profile"; then
        fs_fail "$FS_ERR_PROFILE_NOT_FOUND" "profile"
        return 1
    fi

}

###############################################################################
# Initialize
###############################################################################

fs_command_ignore_init() {

    local profile="$1"

    fs_ignore_require_profile "$profile" || return 1

    if fs_ignore_exists "$profile"; then

        printf 'Ignore file already exists for profile: %s\n' "$profile"

        return 0

    fi

    fs_ignore_init "$profile"

    printf 'Created %s for profile: %s\n' \
        "$FS_IGNORE_FILE" \
        "$profile"

}

###############################################################################
# List
###############################################################################

fs_command_ignore_list() {

    local profile="$1"

    fs_ignore_require_profile "$profile" || return 1

    if ! fs_ignore_exists "$profile"; then

        fs_log_error \
            "Ignore file does not exist for profile: ${profile}"

        return 1

    fi

    fs_ignore_list "$profile"

}

###############################################################################
# Show
###############################################################################

fs_command_ignore_show() {

    local profile="$1"

    fs_ignore_require_profile "$profile" || return 1

    if ! fs_ignore_exists "$profile"; then

        fs_log_error \
            "Ignore file does not exist for profile: ${profile}"

        return 1

    fi

    fs_ignore_print "$profile"

}

###############################################################################
# Add
###############################################################################

fs_command_ignore_add() {

    local profile="$1"
    local pattern="$2"

    fs_ignore_require_profile "$profile" || return 1

    if [[ -z "$pattern" ]]; then

        fs_log_error "Ignore pattern is required."

        return 1

    fi

    fs_ignore_add "$profile" "$pattern"

    printf 'Added ignore pattern: %s\n' "$pattern"

}

###############################################################################
# Remove
###############################################################################

fs_command_ignore_remove() {

    local profile="$1"
    local pattern="$2"

    fs_ignore_require_profile "$profile" || return 1

    if [[ -z "$pattern" ]]; then

        fs_log_error "Ignore pattern is required."

        return 1

    fi

    fs_ignore_remove "$profile" "$pattern"

    printf 'Removed ignore pattern: %s\n' "$pattern"

}

###############################################################################
# Reset
###############################################################################

fs_command_ignore_reset() {

    local profile="$1"

    fs_ignore_require_profile "$profile" || return 1

    fs_ignore_reset "$profile"

    printf 'Reset %s for profile: %s\n' \
        "$FS_IGNORE_FILE" \
        "$profile"

}

###############################################################################
# Information
###############################################################################

fs_command_ignore_info() {

    local profile="$1"

    fs_ignore_require_profile "$profile" || return 1

    fs_ignore_info "$profile"

}

###############################################################################
# Main
###############################################################################

fs_command_ignore() {

    local profile=""
    local action=""
    local pattern=""

    if [[ $# -eq 0 ]]; then

        fs_ignore_help

        return 0

    fi

    case "${1:-}" in

        -h|--help)

            fs_ignore_help
            return 0
            ;;

    esac

    profile="${1:-}"
    shift

    if [[ -z "$profile" ]]; then

        fs_log_error "Profile is required."

        fs_ignore_help

        return 1

    fi

    action="${1:-}"
    shift || true

    case "$action" in

        init)

            fs_command_ignore_init "$profile"
            ;;

        list)

            fs_command_ignore_list "$profile"
            ;;

        show)

            fs_command_ignore_show "$profile"
            ;;

        add)

            pattern="${1:-}"

            fs_command_ignore_add \
                "$profile" \
                "$pattern"
            ;;

        remove)

            pattern="${1:-}"

            fs_command_ignore_remove \
                "$profile" \
                "$pattern"
            ;;

        reset)

            fs_command_ignore_reset "$profile"
            ;;

        info)

            fs_command_ignore_info "$profile"
            ;;

        -h|--help)

            fs_ignore_help
            ;;

        "")

            fs_ignore_help
            return 1
            ;;

        *)

            fs_log_error \
                "Unknown ignore command: ${action}"

            printf '\n'

            fs_ignore_help

            return 1
            ;;

    esac

}

###############################################################################
# Execute
###############################################################################

fs_command_ignore "$@"