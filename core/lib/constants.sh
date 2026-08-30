#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/constants.sh
#
# Description:
#   Global immutable application constants.
#
# Responsibilities:
#   • Application identity
#   • File-name contracts
#   • Profile naming rules
#   • Service naming
#   • Runtime status values
#   • Health values
#   • Shared boolean values
#
###############################################################################

if [[ "${FS_CONSTANTS_LOADED:-false}" == "true" ]]; then
    return 0
fi

FS_CONSTANTS_LOADED=true

set -euo pipefail

###############################################################################
# Application
###############################################################################

readonly FS_APP_NAME="FolderSynka"
readonly FS_EXECUTABLE="foldersynka"

###############################################################################
# File Names
###############################################################################

readonly FS_PROFILE_CONFIG_EXTENSION=".conf"
readonly FS_RUNTIME_FILE="runtime.conf"
readonly FS_IGNORE_FILE=".foldersynkaignore"

###############################################################################
# Profile
###############################################################################

readonly FS_PROFILE_NAME_MAX_LENGTH=64
readonly FS_PROFILE_NAME_REGEX='^[a-zA-Z0-9._-]+$'

###############################################################################
# Service
###############################################################################

readonly FS_SERVICE_PREFIX="foldersynka"

###############################################################################
# Logging
###############################################################################

readonly FS_LOG_DATE_FORMAT="%Y-%m-%d"
readonly FS_LOG_TIMESTAMP_FORMAT="%Y-%m-%dT%H:%M:%SZ"

###############################################################################
# Runtime Status
###############################################################################

readonly FS_STATUS_STOPPED="stopped"
readonly FS_STATUS_STARTING="starting"
readonly FS_STATUS_RUNNING="running"
readonly FS_STATUS_SYNCING="syncing"
readonly FS_STATUS_STOPPING="stopping"
readonly FS_STATUS_ERROR="error"

###############################################################################
# Health
###############################################################################

readonly FS_HEALTH_HEALTHY="healthy"
readonly FS_HEALTH_WARNING="warning"
readonly FS_HEALTH_UNHEALTHY="unhealthy"

###############################################################################
# Boolean
###############################################################################

readonly FS_TRUE="true"
readonly FS_FALSE="false"

###############################################################################
# End of File
###############################################################################