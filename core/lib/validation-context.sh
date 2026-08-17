#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/validation-context.sh
#
# Description:
#   Shared validation context for FolderSynka.
#
# Responsibilities:
#   • Store validation results
#   • Provide validation state API
#   • Connect validation with application errors
#   • Decouple validation state from CLI commands
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/errors.sh"

###############################################################################
# Validation Context
###############################################################################

FS_VALIDATION_OK=true
FS_VALIDATION_CODE=""
FS_VALIDATION_FIELD=""
FS_VALIDATION_MESSAGE=""

###############################################################################
# Reset
###############################################################################

fs_validation_reset() {
    FS_VALIDATION_OK=true
    FS_VALIDATION_CODE=""
    FS_VALIDATION_FIELD=""
    FS_VALIDATION_MESSAGE=""

    fs_error_reset
}

###############################################################################
# Success
###############################################################################

fs_validation_success() {
    fs_validation_reset

    return 0
}

###############################################################################
# Failure
###############################################################################

fs_validation_fail() {
    local code="$1"
    local field="${2:-}"

    FS_VALIDATION_OK=false
    FS_VALIDATION_CODE="$code"
    FS_VALIDATION_FIELD="$field"

    fs_error_set "$code" "$field"

    FS_VALIDATION_MESSAGE="$(fs_error_message)"

    return 1
}

###############################################################################
# State
###############################################################################

fs_validation_ok() {
    [[ "$FS_VALIDATION_OK" == "$FS_TRUE" ]]
}

###############################################################################
# Accessors
###############################################################################

fs_validation_code() {
    printf '%s\n' "$FS_VALIDATION_CODE"
}

fs_validation_message() {
    printf '%s\n' "$FS_VALIDATION_MESSAGE"
}

fs_validation_field() {
    printf '%s\n' "$FS_VALIDATION_FIELD"
}

###############################################################################
# Assertion
###############################################################################

fs_validation_require() {
    local condition="$1"
    local code="$2"
    local field="${3:-}"

    if [[ "$condition" != "$FS_TRUE" ]]; then
        fs_validation_fail "$code" "$field"
        return 1
    fi

    return 0
}

###############################################################################
# End of File
###############################################################################