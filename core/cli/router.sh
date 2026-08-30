#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/router.sh
#
# Description:
#   Central CLI command router.
###############################################################################

set -euo pipefail

###############################################################################
# Environment
###############################################################################

if [[ -z "${FS_HOME:-}" ]]; then
    printf 'FolderSynka environment not initialized.\n' >&2
    exit 1
fi

###############################################################################
# Paths
###############################################################################

CLI_DIR="${FS_HOME}/core/cli"
COMMAND_DIR="${CLI_DIR}/commands"

###############################################################################
# Command
###############################################################################

COMMAND="${1:-help}"

if [[ $# -gt 0 ]]; then
    shift
fi

###############################################################################
# Global Flags
###############################################################################

case "$COMMAND" in

    -h|--help)
        COMMAND="help"
        ;;

    -v|--version)
        COMMAND="version"
        ;;

esac

###############################################################################
# Dispatch
###############################################################################

case "$COMMAND" in

    help)
        exec bash "${CLI_DIR}/help.sh" "$@"
        ;;

    version)
        exec bash "${COMMAND_DIR}/version.sh" "$@"
        ;;

    create)
        exec bash "${COMMAND_DIR}/create.sh" "$@"
        ;;

    start)
        exec bash "${COMMAND_DIR}/start.sh" "$@"
        ;;

    stop)
        exec bash "${COMMAND_DIR}/stop.sh" "$@"
        ;;

    restart)
        exec bash "${COMMAND_DIR}/restart.sh" "$@"
        ;;

    status)
        exec bash "${COMMAND_DIR}/status.sh" "$@"
        ;;

    list)
        exec bash "${COMMAND_DIR}/list.sh" "$@"
        ;;

    remove)
        exec bash "${COMMAND_DIR}/remove.sh" "$@"
        ;;

    doctor)
        exec bash "${COMMAND_DIR}/doctor.sh" "$@"
        ;;

    ignore)
        exec bash "${COMMAND_DIR}/ignore.sh" "$@"
        ;;

    *)
        printf '\nUnknown command: %s\n\n' "$COMMAND" >&2
        bash "${CLI_DIR}/help.sh" >&2
        exit 1
        ;;

esac