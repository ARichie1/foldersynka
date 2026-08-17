#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/environment.sh
#
# Description:
#   Environment detection and inspection utilities.
#
# Responsibilities:
#   • Detect the execution platform
#   • Detect Android storage
#   • Check command availability
#   • Inspect environment variables
#   • Provide runtime environment information
#
###############################################################################

set -euo pipefail

###############################################################################
# Platform
###############################################################################

fs_is_termux() {
    [[ -n "${PREFIX:-}" ]] &&
    [[ "$PREFIX" == *"com.termux"* ]]
}

fs_os() {
    uname -s
}

fs_architecture() {
    uname -m
}

###############################################################################
# Storage
###############################################################################

fs_storage_directory() {
    printf '%s\n' "/storage/emulated/0"
}

fs_storage_available() {
    [[ -d "$(fs_storage_directory)" ]]
}

###############################################################################
# Commands
###############################################################################

fs_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

###############################################################################
# Environment Variables
###############################################################################

fs_environment_variable_exists() {
    [[ -n "${!1:-}" ]]
}

###############################################################################
# Runtime Information
###############################################################################

fs_hostname() {
    hostname
}

fs_username() {
    whoami
}

###############################################################################
# End of File
###############################################################################