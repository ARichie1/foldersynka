#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/utils/terminal.sh
#
# Description:
#   Terminal output and interaction utilities.
#
# Responsibilities:
#   • Colored output
#   • Status messages
#   • Headers
#   • Sections
#   • Prompts
#   • Confirmation
#   • Formatting
#
###############################################################################

set -euo pipefail

###############################################################################
# Colors
###############################################################################

readonly FS_COLOR_RESET="\033[0m"
readonly FS_COLOR_BLACK="\033[30m"
readonly FS_COLOR_RED="\033[31m"
readonly FS_COLOR_GREEN="\033[32m"
readonly FS_COLOR_YELLOW="\033[33m"
readonly FS_COLOR_BLUE="\033[34m"
readonly FS_COLOR_MAGENTA="\033[35m"
readonly FS_COLOR_CYAN="\033[36m"
readonly FS_COLOR_WHITE="\033[37m"
readonly FS_COLOR_BOLD="\033[1m"

###############################################################################
# Symbols
###############################################################################

readonly FS_ICON_SUCCESS="✓"
readonly FS_ICON_ERROR="✗"
readonly FS_ICON_WARNING="!"
readonly FS_ICON_INFO="•"
readonly FS_ICON_ARROW="➜"

###############################################################################
# Internal Printer
###############################################################################

_fs_print() {
    local color="$1"
    local prefix="$2"

    shift 2

    printf "%b%s%b %s\n" \
        "$color" \
        "$prefix" \
        "$FS_COLOR_RESET" \
        "$*"
}

###############################################################################
# Status Messages
###############################################################################

fs_print_success() {
    _fs_print \
        "$FS_COLOR_GREEN" \
        "$FS_ICON_SUCCESS" \
        "$@"
}

fs_print_error() {
    _fs_print \
        "$FS_COLOR_RED" \
        "$FS_ICON_ERROR" \
        "$@" >&2
}

fs_print_warning() {
    _fs_print \
        "$FS_COLOR_YELLOW" \
        "$FS_ICON_WARNING" \
        "$@"
}

fs_print_info() {
    _fs_print \
        "$FS_COLOR_CYAN" \
        "$FS_ICON_INFO" \
        "$@"
}

fs_print() {
    printf "%s\n" "$*"
}

###############################################################################
# Formatting
###############################################################################

fs_print_blank() {
    printf "\n"
}

fs_print_divider() {
    local width="${COLUMNS:-80}"

    printf '%*s\n' "$width" '' | tr ' ' '-'
}

fs_print_header() {
    fs_print_blank

    printf "%b%s%b\n" \
        "$FS_COLOR_BOLD$FS_COLOR_BLUE" \
        "$*" \
        "$FS_COLOR_RESET"

    fs_print_divider
}

fs_print_section() {
    fs_print_blank

    printf "%b%s%b\n" \
        "$FS_COLOR_BOLD" \
        "$*" \
        "$FS_COLOR_RESET"
}

fs_print_key_value() {
    printf "%-22s : %s\n" "$1" "$2"
}

fs_print_item() {
    printf "  %s %s\n" \
        "$FS_ICON_ARROW" \
        "$1"
}

###############################################################################
# Input
###############################################################################

fs_prompt() {
    local message="$1"
    local response

    printf "%s: " "$message"
    read -r response

    printf "%s\n" "$response"
}

fs_confirm() {
    local message="$1"
    local response

    printf "%s [y/N]: " "$message"
    read -r response

    case "$response" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

###############################################################################
# Fatal Error
###############################################################################

fs_die() {
    fs_print_error "$@"
    exit 1
}

###############################################################################
# Banner
###############################################################################

fs_print_banner() {
    cat <<'EOF'

███████╗ ██████╗ ██╗     ██████╗ ███████╗██████╗
██╔════╝██╔═══██╗██║     ██╔══██╗██╔════╝██╔══██╗
█████╗  ██║   ██║██║     ██║  ██║█████╗  ██████╔╝
██╔══╝  ██║   ██║██║     ██║  ██║██╔══╝  ██╔══██╗
██║     ╚██████╔╝███████╗██████╔╝███████╗██║  ██║
╚═╝      ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝

                 FolderSynka

EOF
}

###############################################################################
# End
###############################################################################