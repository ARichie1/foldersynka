#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/config/ignore.sh
#
# Description:
#   Canonical .foldersynkaignore management API.
#
# Responsibilities:
#   • Resolve profile ignore files
#   • Create and initialize ignore files
#   • Validate ignore files
#   • Read ignore patterns
#   • Add and remove ignore patterns
#   • Test paths against ignore patterns
#   • Reset ignore files from the canonical template
#
# This module must not:
#   • Parse CLI arguments
#   • Start or stop services
#   • Modify profile configuration
#   • Modify runtime state
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/lib/error-codes.sh"
source "${FS_HOME}/core/lib/validation-context.sh"

###############################################################################
# Ignore File Resolution
###############################################################################

fs_ignore_file() {
    local profile="$1"

    fs_profile_load "$profile"

    printf '%s\n' \
        "${FS_PROFILE_SOURCE}/${FS_IGNORE_FILE}"
}

fs_ignore_exists() {
    local profile="$1"
    local file

    file="$(fs_ignore_file "$profile")"

    [[ -f "$file" ]]
}

###############################################################################
# Ignore File Creation
###############################################################################

fs_ignore_create() {
    local profile="$1"
    local file
    local template

    fs_profile_load "$profile"

    file="${FS_PROFILE_SOURCE}/${FS_IGNORE_FILE}"
    template="$FS_DEFAULT_IGNORE_TEMPLATE"

    [[ -f "$file" ]] && return 0

    [[ -f "$template" ]] || {
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_NOT_FOUND" \
            "$template"

        return 1
    }

    cp -- "$template" "$file"
}

###############################################################################
# Ignore File Initialization
###############################################################################

fs_ignore_init() {
    local profile="$1"

    if fs_ignore_exists "$profile"; then
        return 0
    fi

    fs_ignore_create "$profile"
}

###############################################################################
# Ignore File Validation
###############################################################################

fs_ignore_validate() {
    local profile="$1"
    local file

    fs_profile_load "$profile"

    file="${FS_PROFILE_SOURCE}/${FS_IGNORE_FILE}"

    if [[ ! -e "$file" ]]; then
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_NOT_FOUND" \
            "$file"

        return 1
    fi

    if [[ ! -f "$file" ]]; then
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_INVALID" \
            "$file"

        return 1
    fi

    if [[ ! -r "$file" ]]; then
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_NOT_READABLE" \
            "$file"

        return 1
    fi

    fs_validation_success
}

###############################################################################
# Pattern Normalization
###############################################################################

fs_ignore_normalize_pattern() {
    local pattern="$1"

    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern%"${pattern##*[![:space:]]}"}"

    printf '%s\n' "$pattern"
}

###############################################################################
# Pattern Validation
###############################################################################

fs_ignore_validate_pattern() {
    local pattern="$1"

    pattern="$(fs_ignore_normalize_pattern "$pattern")"

    [[ -n "$pattern" ]] || return 1
    [[ "$pattern" != \#* ]] || return 1
}

###############################################################################
# Pattern Existence
###############################################################################

fs_ignore_contains() {
    local profile="$1"
    local pattern="$2"
    local file
    local normalized

    normalized="$(fs_ignore_normalize_pattern "$pattern")"
    file="$(fs_ignore_file "$profile")"

    [[ -f "$file" ]] || return 1
    [[ -n "$normalized" ]] || return 1

    grep -Fqx -- "$normalized" "$file"
}

###############################################################################
# List Patterns
###############################################################################

fs_ignore_read() {
    local profile="$1"

    fs_ignore_validate "$profile" || return 1
    fs_ignore_print "$profile"
}

fs_ignore_list() {
    local profile="$1"
    local file

    file="$(fs_ignore_file "$profile")"

    fs_ignore_validate "$profile" || return 1

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(fs_ignore_normalize_pattern "$line")"

        [[ -n "$line" ]] || continue
        [[ "$line" == \#* ]] && continue

        printf '%s\n' "$line"
    done < "$file"
}

###############################################################################
# Add Pattern
###############################################################################

fs_ignore_add() {
    local profile="$1"
    local pattern="$2"
    local file

    file="$(fs_ignore_file "$profile")"

    fs_ignore_validate_pattern "$pattern" || {
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_INVALID" \
            "$pattern"

        return 1
    }

    fs_ignore_init "$profile"

    pattern="$(fs_ignore_normalize_pattern "$pattern")"

    if fs_ignore_contains "$profile" "$pattern"; then
        return 0
    fi

    if [[ -s "$file" ]] && [[ -n "$(tail -c 1 "$file")" ]]; then
        printf '\n' >> "$file"
    fi

    printf '%s\n' "$pattern" >> "$file"
}

###############################################################################
# Remove Pattern
###############################################################################

fs_ignore_remove() {
    local profile="$1"
    local pattern="$2"
    local file
    local normalized
    local temporary

    file="$(fs_ignore_file "$profile")"

    fs_ignore_validate "$profile" || return 1

    normalized="$(fs_ignore_normalize_pattern "$pattern")"

    fs_ignore_validate_pattern "$normalized" || {
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_INVALID" \
            "$pattern"

        return 1
    }

    if ! fs_ignore_contains "$profile" "$normalized"; then
        return 0
    fi

    temporary="$(mktemp)"

    awk -v pattern="$normalized" '
        $0 != pattern {
            print
        }
    ' "$file" > "$temporary"

    mv -- "$temporary" "$file"
}

###############################################################################
# Path Matching
###############################################################################

fs_ignore_is_ignored() {
    local profile="$1"
    local path="$2"
    local file
    local pattern
    local match_pattern
    local match_pattern

    fs_ignore_validate "$profile" || return 1

    file="$(fs_ignore_file "$profile")"

    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        pattern="$(fs_ignore_normalize_pattern "$pattern")"

        [[ -n "$pattern" ]] || continue
        [[ "$pattern" == \#* ]] && continue

        match_pattern="${pattern%/}"

        if [[ "$path" == $pattern || "$path" == $match_pattern ]]; then
            return 0
        fi

        if [[ "$path" == */$match_pattern || "$path" == */$match_pattern/* ]]; then
            return 0
        fi

        if [[ "$path" == $match_pattern/* ]]; then
            return 0
        fi

        if [[ "$pattern" == *"*"* || "$pattern" == *"?"* ]]; then
            if [[ "$path" == $pattern || "$path" == $match_pattern ]]; then
                return 0
            fi
        fi
    done < "$file"

    return 1
}

###############################################################################
# Print Ignore File
###############################################################################

fs_ignore_print() {
    local profile="$1"
    local file

    file="$(fs_ignore_file "$profile")"

    fs_ignore_validate "$profile" || return 1

    cat -- "$file"
}

###############################################################################
# Reset Ignore File
###############################################################################

fs_ignore_reset() {
    local profile="$1"
    local file
    local template
    local temporary

    fs_profile_load "$profile"

    file="${FS_PROFILE_SOURCE}/${FS_IGNORE_FILE}"
    template="$FS_DEFAULT_IGNORE_TEMPLATE"

    [[ -f "$template" ]] || {
        fs_validation_fail \
            "$FS_ERR_IGNORE_FILE_NOT_FOUND" \
            "$template"

        return 1
    }

    temporary="$(mktemp)"

    cp -- "$template" "$temporary"
    mv -- "$temporary" "$file"
}

###############################################################################
# Ignore File Information
###############################################################################

fs_ignore_info() {
    local profile="$1"
    local file

    file="$(fs_ignore_file "$profile")"

    printf 'Ignore File : %s\n' "$file"

    if [[ -f "$file" ]]; then
        printf 'Status      : initialized\n'
        printf 'Patterns    : %s\n' \
            "$(fs_ignore_list "$profile" | wc -l)"
    else
        printf 'Status      : not initialized\n'
        printf 'Patterns    : 0\n'
    fi
}

###############################################################################
# End of File
###############################################################################