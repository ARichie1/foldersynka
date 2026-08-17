#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/pipeline.sh
#
# Description:
#   Shared validation-pipeline dispatcher and execution helpers.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/errors.sh"
source "${FS_HOME}/core/lib/validation-context.sh"

###############################################################################
# Pipeline Result
###############################################################################

fs_pipeline_success() {
    fs_validation_success
    return 0
}

fs_pipeline_failure() {
    return 1
}

###############################################################################
# Pipeline Step
###############################################################################

fs_pipeline_step() {
    local validator="$1"
    shift

    if ! declare -F "$validator" >/dev/null 2>&1; then
        fs_fail \
            "$FS_ERR_INTERNAL" \
            "validation"
    fi

    "$validator" "$@"
}

###############################################################################
# Pipeline Dispatcher
###############################################################################

fs_run_validation_pipeline() {
    local pipeline="$1"
    shift

    local file="${FS_HOME}/core/validation/${pipeline}.sh"
    local function="fs_validation_pipeline_${pipeline}"

    if [[ ! -f "$file" ]]; then
        fs_fail \
            "$FS_ERR_INTERNAL" \
            "validation"
    fi

    # shellcheck disable=SC1090
    source "$file"

    if ! declare -F "$function" >/dev/null 2>&1; then
        fs_fail \
            "$FS_ERR_INTERNAL" \
            "validation"
    fi

    "$function" "$@"
}