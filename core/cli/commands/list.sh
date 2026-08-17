#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/list.sh
#
# Description:
#   List configured FolderSynka profiles.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"
source "${FS_HOME}/core/config/profile.sh"

###############################################################################
# Help
###############################################################################

fs_list_help() {

    cat <<EOF

List FolderSynka profiles.

Usage

    foldersynka list

EOF

}

###############################################################################
# Main
###############################################################################

fs_command_list() {

    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        fs_list_help
        return 0
    fi

    local profiles

    profiles="$(fs_profile_list)"

    if [[ -z "$profiles" ]]; then
        printf 'No profiles configured.\n'
        return 0
    fi

    printf '\n'
    printf 'FolderSynka Profiles\n'
    printf '%s\n' '--------------------'

    while IFS= read -r profile; do

        [[ -n "$profile" ]] || continue

        printf '%s\n' "$profile"

    done <<< "$profiles"

    printf '\n'

}

###############################################################################
# Execute
###############################################################################

fs_command_list "$@"