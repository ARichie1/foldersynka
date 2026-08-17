#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/doctor.sh
#
# Description:
#   Validation pipeline for FolderSynka system diagnostics.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/validation/pipeline.sh"
source "${FS_HOME}/core/utils/validation.sh"

###############################################################################
# Doctor Pipeline
###############################################################################

fs_validation_pipeline_doctor() {
    fs_pipeline_step \
        fs_validate_termux_environment \
        || return 1

    fs_pipeline_step \
        fs_validate_home \
        || return 1

    fs_pipeline_step \
        fs_validate_prefix \
        || return 1

    fs_pipeline_step \
        fs_validate_path_environment \
        || return 1

    fs_pipeline_step \
        fs_validate_tmpdir \
        || return 1

    fs_pipeline_step \
        fs_validate_storage \
        || return 1

    fs_pipeline_step \
        fs_validate_storage_permission \
        || return 1

    fs_pipeline_step \
        fs_validate_rsync \
        || return 1

    fs_pipeline_step \
        fs_validate_inotify \
        || return 1

    fs_pipeline_step \
        fs_validate_sv \
        || return 1

    fs_pipeline_step \
        fs_validate_termux_services \
        || return 1

    fs_pipeline_step \
        fs_validate_runtime \
        || return 1

    fs_pipeline_success
}