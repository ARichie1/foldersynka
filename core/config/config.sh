#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/config/config.sh
#
# Description:
#   Public configuration API.
#
# Responsibilities:
#   • Load configuration dependencies in a defined order
#   • Expose the complete configuration subsystem
#
# This is the preferred entry point for application modules that require
# FolderSynka configuration functionality.
###############################################################################

set -euo pipefail

###############################################################################
# Core Contracts
###############################################################################

source "${FS_HOME}/core/lib/constants.sh"
source "${FS_HOME}/core/config/defaults.sh"

###############################################################################
# Filesystem Paths
###############################################################################

source "${FS_HOME}/core/config/paths.sh"

###############################################################################
# Runtime Configuration
###############################################################################

source "${FS_HOME}/core/config/runtime.sh"

###############################################################################
# Profile Configuration
###############################################################################

source "${FS_HOME}/core/config/profile.sh"

###############################################################################
# Runtime State
###############################################################################

source "${FS_HOME}/core/config/state.sh"

###############################################################################
# End of File
###############################################################################