#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/config/defaults.sh
#
# Description:
#   Default configuration values used when creating profiles.
#
# Responsibilities:
#   • Define default profile configuration
#   • Define default synchronization behavior
#   • Define default service behavior
#   • Define default runtime behavior
#
# These values may be overridden by individual profiles.
###############################################################################

if [[ "${FS_DEFAULTS_LOADED:-false}" == "true" ]]; then
    return 0
fi

FS_DEFAULTS_LOADED=true

set -euo pipefail

###############################################################################
# Configuration
###############################################################################

readonly FS_DEFAULT_CONFIG_VERSION="1.0.0"

###############################################################################
# Synchronization
###############################################################################

readonly FS_DEFAULT_WATCH=true
readonly FS_DEFAULT_DELETE=false
readonly FS_DEFAULT_COMPRESS=true
readonly FS_DEFAULT_CHECKSUM=false
readonly FS_DEFAULT_FOLLOW_SYMLINKS=false

readonly FS_DEFAULT_SYNC_INTERVAL=3
readonly FS_DEFAULT_DEBOUNCE_MS=500
readonly FS_DEFAULT_DEBOUNCE=0.5

readonly FS_DEFAULT_RSYNC_FLAGS="-a"

###############################################################################
# Service
###############################################################################

readonly FS_DEFAULT_AUTO_START=false

###############################################################################
# Logging
###############################################################################

readonly FS_DEFAULT_LOG_LEVEL="info"

###############################################################################
# Retry
###############################################################################

readonly FS_DEFAULT_RETRY_DELAY=2

###############################################################################
# Watcher
###############################################################################

readonly FS_DEFAULT_WATCH_EVENTS="modify,create,delete,move"

###############################################################################
# End of File
###############################################################################