#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/doctor.sh
#
# Description:
#   Diagnose the FolderSynka installation and runtime environment.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/validation/pipeline.sh"

###############################################################################
# Help
###############################################################################

fs_doctor_help() {

    cat <<EOF

Usage

    foldersynka doctor [profile]

Description

    Diagnose the FolderSynka installation, dependencies,
    runtime, profiles, and services.

Examples

    foldersynka doctor

    foldersynka doctor my-project

EOF

}

###############################################################################
# Main
###############################################################################

fs_command_doctor() {

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        fs_doctor_help
        return 0
    fi

    local profile="${1:-}"

    printf '\n'
    printf 'FolderSynka Doctor\n'
    printf '%s\n' '=================='
    printf '\n'

    ###########################################################################
    # Validation Pipeline
    ###########################################################################

    if [[ -n "$profile" ]]; then

        if fs_run_validation_pipeline \
            doctor \
            "$profile"; then

            printf 'Overall Health : Healthy ✓\n'

        else

            printf 'Overall Health : Attention Required\n'

            return 1

        fi

    else

        if fs_run_validation_pipeline \
            doctor; then

            printf 'Overall Health : Healthy ✓\n'

        else

            printf 'Overall Health : Attention Required\n'

            return 1

        fi

    fi

    printf '\n'

}

###############################################################################
# Execute
###############################################################################

fs_command_doctor "$@"