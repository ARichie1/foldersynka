#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: install.sh
#
# Description:
#   Install FolderSynka into the Termux environment.
#
# Responsibilities:
#   • Validate the repository
#   • Install application files
#   • Install the executable
#   • Set required permissions
#   • Verify the installation
#
###############################################################################

set -euo pipefail

###############################################################################
# Project Paths
###############################################################################

readonly FS_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly FS_INSTALL_HOME="${PREFIX}/share/foldersynka"
readonly FS_INSTALL_BIN="${PREFIX}/bin/foldersynka"

readonly FS_SOURCE_BIN="${FS_SOURCE_DIR}/bin"
readonly FS_SOURCE_CORE="${FS_SOURCE_DIR}/core"
readonly FS_SOURCE_VERSION="${FS_SOURCE_DIR}/VERSION"

###############################################################################
# Output Helpers
###############################################################################

fs_install_info() {

    printf '  • %s\n' "$1"

}

fs_install_error() {

    printf '\nFolderSynka installation failed.\n\n' >&2
    printf 'Error: %s\n' "$1" >&2

    exit 1

}

###############################################################################
# Environment
###############################################################################

fs_install_validate_environment() {

    [[ -n "${PREFIX:-}" ]] || \
        fs_install_error "PREFIX is not configured."

    [[ -n "${HOME:-}" ]] || \
        fs_install_error "HOME is not configured."

    if [[ "$PREFIX" != *"/com.termux"* ]]; then

        fs_install_error \
            "This installer is intended for Termux."

    fi

}

###############################################################################
# Repository Validation
###############################################################################

fs_validate_repository() {

    [[ -d "$FS_SOURCE_CORE" ]] || \
        fs_install_error "core/ directory not found."

    [[ -d "$FS_SOURCE_BIN" ]] || \
        fs_install_error "bin/ directory not found."

    [[ -f "$FS_SOURCE_BIN/foldersynka" ]] || \
        fs_install_error "bin/foldersynka not found."

    [[ -f "$FS_SOURCE_CORE/cli/router.sh" ]] || \
        fs_install_error "core/cli/router.sh not found."

    [[ -f "$FS_SOURCE_VERSION" ]] || \
        fs_install_error "VERSION file not found."

}

###############################################################################
# Prepare Installation
###############################################################################

fs_prepare_installation() {

    mkdir -p "$FS_INSTALL_HOME"
    mkdir -p "${PREFIX}/bin"

}

###############################################################################
# Install Application
###############################################################################

fs_install_application() {

    fs_install_info "Installing application files..."

    rm -rf "$FS_INSTALL_HOME"

    mkdir -p "$FS_INSTALL_HOME"

    cp -R "$FS_SOURCE_CORE" \
        "$FS_INSTALL_HOME/"

    cp "$FS_SOURCE_VERSION" \
        "$FS_INSTALL_HOME/"

}

###############################################################################
# Install Executable
###############################################################################

fs_install_executable() {

    fs_install_info "Installing executable..."

    cp "$FS_SOURCE_BIN/foldersynka" \
        "$FS_INSTALL_BIN"

    chmod 755 "$FS_INSTALL_BIN"

}

###############################################################################
# Set Application Permissions
###############################################################################

fs_set_permissions() {

    fs_install_info "Setting application permissions..."

    find "$FS_INSTALL_HOME" \
        -type f \
        -name '*.sh' \
        -exec chmod 755 {} \;

    find "$FS_INSTALL_HOME" \
        -type f \
        ! -name '*.sh' \
        -exec chmod 644 {} \;

}

###############################################################################
# Verify Installation
###############################################################################

fs_verify_installation() {

    fs_install_info "Verifying installation..."

    [[ -x "$FS_INSTALL_BIN" ]] || \
        fs_install_error "Installed executable is not executable."

    [[ -d "$FS_INSTALL_HOME/core" ]] || \
        fs_install_error "Installed core directory is missing."

    [[ -f "$FS_INSTALL_HOME/VERSION" ]] || \
        fs_install_error "Installed VERSION file is missing."

    [[ -x "$FS_INSTALL_HOME/core/cli/router.sh" ]] || \
        fs_install_error "Installed CLI router is not executable."

}

###############################################################################
# Installation Summary
###############################################################################

fs_print_summary() {

    local version

    version="$(<"$FS_INSTALL_HOME/VERSION")"

    printf '\n'
    printf 'FolderSynka installed successfully.\n\n'

    printf 'Version      : %s\n' "$version"
    printf 'Application  : %s\n' "$FS_INSTALL_HOME"
    printf 'Executable   : %s\n' "$FS_INSTALL_BIN"

    printf '\n'
    printf 'Try:\n'
    printf '  foldersynka --help\n'
    printf '\n'

}

###############################################################################
# Main
###############################################################################

fs_install() {

    printf '\n'
    printf 'FolderSynka Installer\n'
    printf '=====================\n'
    printf '\n'

    fs_install_validate_environment
    fs_validate_repository

    fs_prepare_installation
    fs_install_application
    fs_install_executable
    fs_set_permissions
    fs_verify_installation

    fs_print_summary

}

###############################################################################
# Execute
###############################################################################

fs_install "$@"
