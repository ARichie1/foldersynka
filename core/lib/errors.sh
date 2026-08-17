#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/errors.sh
#
# Description:
#   Central application error management API.
#
# Responsibilities:
#   • Maintain error state
#   • Perform registry lookups
#   • Format errors
#   • Print errors
#   • Manage error lifecycle
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/error-codes.sh"
source "${FS_HOME}/core/lib/exit-codes.sh"
source "${FS_HOME}/core/lib/error-registry.sh"

###############################################################################
# Error Context
###############################################################################

FS_ERROR_CODE=""
FS_ERROR_MESSAGE=""
FS_ERROR_FIELD=""
FS_ERROR_EXIT_CODE="$FS_EXIT_SUCCESS"
FS_ERROR_SEVERITY=""
FS_ERROR_HINT=""

###############################################################################
# Reset
###############################################################################

fs_error_reset() {
    FS_ERROR_CODE=""
    FS_ERROR_MESSAGE=""
    FS_ERROR_FIELD=""
    FS_ERROR_EXIT_CODE="$FS_EXIT_SUCCESS"
    FS_ERROR_SEVERITY=""
    FS_ERROR_HINT=""
}

###############################################################################
# Registry Lookup
###############################################################################

fs_error_lookup() {
    local code="$1"

    FS_ERROR_MESSAGE="${FS_ERROR_MESSAGES[$code]:-${FS_ERROR_MESSAGES[$FS_ERR_UNKNOWN]}}"
    FS_ERROR_EXIT_CODE="${FS_ERROR_EXIT_CODES[$code]:-$FS_EXIT_UNKNOWN_ERROR}"
    FS_ERROR_SEVERITY="${FS_ERROR_SEVERITIES[$code]:-ERROR}"
    FS_ERROR_HINT="${FS_ERROR_HINTS[$code]:-}"
}

###############################################################################
# Set Error
###############################################################################

fs_error_set() {
    local code="$1"
    local field="${2:-}"

    fs_error_reset

    FS_ERROR_CODE="$code"
    FS_ERROR_FIELD="$field"

    fs_error_lookup "$code"
}

###############################################################################
# Error State
###############################################################################

fs_error_has_error() {
    [[ -n "$FS_ERROR_CODE" ]]
}

###############################################################################
# Accessors
###############################################################################

fs_error_code() {
    printf '%s\n' "$FS_ERROR_CODE"
}

fs_error_message() {
    printf '%s\n' "$FS_ERROR_MESSAGE"
}

fs_error_field() {
    printf '%s\n' "$FS_ERROR_FIELD"
}

fs_error_exit_code() {
    printf '%s\n' "$FS_ERROR_EXIT_CODE"
}

fs_error_severity() {
    printf '%s\n' "$FS_ERROR_SEVERITY"
}

fs_error_hint() {
    printf '%s\n' "$FS_ERROR_HINT"
}

###############################################################################
# Output
###############################################################################

fs_error_print() {
    printf '\n'
    printf '[%s] %s\n' \
        "$FS_ERROR_SEVERITY" \
        "$FS_ERROR_MESSAGE"

    if [[ -n "$FS_ERROR_FIELD" ]]; then
        printf 'Field : %s\n' "$FS_ERROR_FIELD"
    fi

    if [[ -n "$FS_ERROR_HINT" ]]; then
        printf 'Hint  : %s\n' "$FS_ERROR_HINT"
    fi

    printf '\n'
}

###############################################################################
# JSON
###############################################################################

fs_error_print_json() {
    cat <<EOF
{
  "code": "${FS_ERROR_CODE}",
  "message": "${FS_ERROR_MESSAGE}",
  "field": "${FS_ERROR_FIELD}",
  "severity": "${FS_ERROR_SEVERITY}",
  "hint": "${FS_ERROR_HINT}",
  "exitCode": ${FS_ERROR_EXIT_CODE}
}
EOF
}

###############################################################################
# Exit
###############################################################################

fs_error_exit() {
    exit "$FS_ERROR_EXIT_CODE"
}

###############################################################################
# Convenience Helper
###############################################################################

fs_fail() {
    local code="$1"
    local field="${2:-}"

    fs_error_set "$code" "$field"
    fs_error_print
    fs_error_exit
}

###############################################################################
# End of File
###############################################################################