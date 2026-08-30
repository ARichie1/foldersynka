#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/remove.sh
#
# Description:
#   Validation pipeline for removing a FolderSynka profile.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/validation/pipeline.sh"
source "${FS_HOME}/core/utils/validation.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

###############################################################################
# Remove Pipeline
###############################################################################

fs_validation_pipeline_remove() {
    local profile="$1"

    fs_pipeline_step \
        fs_validate_environment \
        || return 1

    fs_pipeline_step \
        fs_validate_profile_name \
        "$profile" \
        || return 1

    fs_pipeline_step \
        fs_validate_profile_exists \
        "$profile" \
        || return 1

    fs_pipeline_step \
        fs_validate_runtime \
        || return 1

    local status
    status="$(fs_state_status "$profile")"

    case "$status" in
        starting|syncing|running|stopping)
            fs_validation_fail \
                "$FS_ERR_ALREADY_RUNNING" \
                "profile"
            return 1
            ;;
    esac

    fs_pipeline_success
}