#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: uninstall.sh
#
# Description:
#   Remove the FolderSynka application installation from Termux.
#
# Responsibilities:
#   • Remove the installed executable
#   • Remove the installed application
#
# This script does not remove:
#   • User profiles
#   • Runtime state
#   • Logs
#   • Locks
#   • Caches
#   • User configuration
#
###############################################################################

set -euo pipefail

###############################################################################
# Installation Paths
###############################################################################

readonly FS_INSTALL_HOME="${PREFIX}/share/foldersynka"
readonly FS_INSTALL_BIN="${PREFIX}/bin/foldersynka"

###############################################################################
# Environment
###############################################################################

if [[ -z "${PREFIX:-}" ]]; then

    printf 'FolderSynka: PREFIX is not configured.\n' >&2

    exit 1

fi

###############################################################################
# Remove Installation
###############################################################################

printf '\n'
printf 'FolderSynka Uninstaller\n'
printf '=======================\n'
printf '\n'

if [[ -f "$FS_INSTALL_BIN" ]]; then

    printf 'Removing executable...\n'

    rm -f -- "$FS_INSTALL_BIN"

fi

if [[ -d "$FS_INSTALL_HOME" ]]; then

    printf 'Removing application files...\n'

    rm -rf -- "$FS_INSTALL_HOME"

fi

###############################################################################
# Summary
###############################################################################

printf '\n'
printf 'FolderSynka uninstalled successfully.\n'
printf '\n'

printf 'User runtime data was preserved:\n'
printf '  %s\n' "${HOME:-\$HOME}/.foldersynka"

printf '\n'