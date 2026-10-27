#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
#
# File:
#   core/validation/stop.sh
#
# Description:
#   Validation pipeline for the stop command.
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
# Stop Pipeline
###############################################################################

fs_validation_pipeline_stop() {
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

    fs_pipeline_step \
        fs_validate_termux_services \
        || return 1

    fs_pipeline_step \
        fs_validate_service_exists \
        "$profile" \
        || return 1

    # Stopping is idempotent and must work even when stale/corrupt sync state
    # no longer reflects the supervisor's process state.

    fs_pipeline_success
}
