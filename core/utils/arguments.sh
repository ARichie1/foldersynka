#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/utils/arguments.sh
#
# Description:
#   Command-line argument parsing utilities.
#
# Responsibilities:
#   • Parse command arguments
#   • Store parsed values
#   • Validate required option values
#   • Report unknown options
#
# This module does not own application configuration or command behavior.
#
###############################################################################

set -euo pipefail

###############################################################################
# Argument Storage
###############################################################################

declare -gA FS_ARGS=()

###############################################################################
# Reset
###############################################################################

fs_args_reset() {
    FS_ARGS=()
}

###############################################################################
# Set
###############################################################################

fs_args_set() {
    local key="$1"
    local value="$2"

    FS_ARGS["$key"]="$value"
}

###############################################################################
# Get
###############################################################################

fs_args_get() {
    local key="$1"

    printf "%s" "${FS_ARGS[$key]:-}"
}

###############################################################################
# Exists
###############################################################################

fs_args_has() {
    local key="$1"

    [[ -v "FS_ARGS[$key]" ]]
}

###############################################################################
# Require Value
###############################################################################

fs_args_require_value() {
    local option="$1"
    local value="${2:-}"

    if [[ -z "$value" ]]; then
        printf "foldersynka: missing value for %s\n" "$option" >&2
        return 1
    fi
}

###############################################################################
# Unknown Option
###############################################################################

fs_args_unknown_option() {
    printf "foldersynka: unknown option '%s'\n" "$1" >&2
    return 1
}

###############################################################################
# Parse Create Command
###############################################################################

fs_args_parse_create() {
    fs_args_reset

    local profile="${1:-}"

    if [[ -z "$profile" ]]; then
        printf "foldersynka: missing profile name\n" >&2
        return 1
    fi

    fs_args_set profile "$profile"

    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --src|-s)
                fs_args_require_value "$1" "${2:-}" || return 1
                fs_args_set src "$2"
                shift 2
                ;;
            --dest|-d)
                fs_args_require_value "$1" "${2:-}" || return 1
                fs_args_set dest "$2"
                shift 2
                ;;
            --compress|-c)
                fs_args_set compress true
                shift
                ;;
            --checksum)
                fs_args_set checksum true
                shift
                ;;
            --no-delete)
                fs_args_set delete false
                shift
                ;;
            --watch)
                fs_args_set watch true
                shift
                ;;
            -h|--help)
                fs_args_set help true
                shift
                ;;
            *)
                fs_args_unknown_option "$1"
                return 1
                ;;
        esac
    done
}

###############################################################################
# End
###############################################################################