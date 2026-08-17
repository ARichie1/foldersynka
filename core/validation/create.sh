#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/create.sh
#
# Description:
#   Validation pipeline for creating a FolderSynka profile.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/validation/pipeline.sh"
source "${FS_HOME}/core/utils/validation.sh"

###############################################################################
# Create Pipeline
###############################################################################

fs_validation_pipeline_create() {
    local profile="$1"
    local source="$2"
    local destination="$3"

    fs_pipeline_step \
        fs_validate_environment \
        || return 1

    fs_pipeline_step \
        fs_validate_profile_name \
        "$profile" \
        || return 1

    fs_pipeline_step \
        fs_validate_profile_missing \
        "$profile" \
        || return 1

    fs_pipeline_step \
        fs_validate_source \
        "$source" \
        || return 1

    fs_pipeline_step \
        fs_validate_destination \
        "$destination" \
        || return 1

    fs_pipeline_step \
        fs_validate_ignore_file \
        "$source" \
        || return 1

    fs_pipeline_success
}