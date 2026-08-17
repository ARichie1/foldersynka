#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/sync.sh
#
# Description:
#   Validation pipeline for the sync command.
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
# Sync Pipeline
###############################################################################

fs_validation_pipeline_sync() {
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

    if ! fs_profile_load "$profile"; then
        fs_validation_fail \
            "$FS_ERR_PROFILE_CORRUPTED" \
            "profile"
        return 1
    fi

    fs_pipeline_step \
        fs_validate_source \
        "$FS_PROFILE_SOURCE" \
        || return 1

    fs_pipeline_step \
        fs_validate_destination \
        "$FS_PROFILE_DESTINATION" \
        || return 1

    fs_pipeline_step \
        fs_validate_ignore_file \
        "$FS_PROFILE_SOURCE" \
        || return 1

    fs_pipeline_step \
        fs_validate_rsync \
        || return 1

    fs_pipeline_success
}