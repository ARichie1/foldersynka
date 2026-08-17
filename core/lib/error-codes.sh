#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/error-codes.sh
#
# Description:
#   Central registry of symbolic application error codes.
#
# Responsibilities:
#   • Define stable error identifiers
#   • Separate errors from messages
#   • Provide shared error contracts
#
###############################################################################

set -euo pipefail

###############################################################################
# Generic Errors
###############################################################################

readonly FS_ERR_UNKNOWN="FS_ERR_UNKNOWN"
readonly FS_ERR_INTERNAL="FS_ERR_INTERNAL"
readonly FS_ERR_NOT_IMPLEMENTED="FS_ERR_NOT_IMPLEMENTED"
readonly FS_ERR_INVALID_ARGUMENT="FS_ERR_INVALID_ARGUMENT"
readonly FS_ERR_INVALID_CONFIGURATION="FS_ERR_INVALID_CONFIGURATION"

###############################################################################
# Profile Errors
###############################################################################

readonly FS_ERR_PROFILE_EXISTS="FS_ERR_PROFILE_EXISTS"
readonly FS_ERR_PROFILE_NOT_FOUND="FS_ERR_PROFILE_NOT_FOUND"
readonly FS_ERR_PROFILE_CORRUPTED="FS_ERR_PROFILE_CORRUPTED"
readonly FS_ERR_INVALID_PROFILE_NAME="FS_ERR_INVALID_PROFILE_NAME"

###############################################################################
# Source Errors
###############################################################################

readonly FS_ERR_SOURCE_NOT_FOUND="FS_ERR_SOURCE_NOT_FOUND"
readonly FS_ERR_SOURCE_NOT_READABLE="FS_ERR_SOURCE_NOT_READABLE"
readonly FS_ERR_SOURCE_NOT_DIRECTORY="FS_ERR_SOURCE_NOT_DIRECTORY"

###############################################################################
# Destination Errors
###############################################################################

readonly FS_ERR_DESTINATION_NOT_FOUND="FS_ERR_DESTINATION_NOT_FOUND"
readonly FS_ERR_DESTINATION_NOT_WRITABLE="FS_ERR_DESTINATION_NOT_WRITABLE"
readonly FS_ERR_DESTINATION_INVALID="FS_ERR_DESTINATION_INVALID"
readonly FS_ERR_DESTINATION_UNSAFE="FS_ERR_DESTINATION_UNSAFE"
readonly FS_ERR_DESTINATION_PARENT_NOT_FOUND="FS_ERR_DESTINATION_PARENT_NOT_FOUND"

###############################################################################
# Filesystem Errors
###############################################################################

readonly FS_ERR_PATH_INVALID="FS_ERR_PATH_INVALID"
readonly FS_ERR_PATH_PROTECTED="FS_ERR_PATH_PROTECTED"
readonly FS_ERR_PERMISSION_DENIED="FS_ERR_PERMISSION_DENIED"
readonly FS_ERR_FILESYSTEM="FS_ERR_FILESYSTEM"

###############################################################################
# Ignore File Errors
###############################################################################

readonly FS_ERR_IGNORE_FILE_NOT_FOUND="FS_ERR_IGNORE_FILE_NOT_FOUND"
readonly FS_ERR_IGNORE_FILE_INVALID="FS_ERR_IGNORE_FILE_INVALID"
readonly FS_ERR_IGNORE_FILE_NOT_READABLE="FS_ERR_IGNORE_FILE_NOT_READABLE"

###############################################################################
# Runtime Errors
###############################################################################

readonly FS_ERR_RUNTIME_NOT_INITIALIZED="FS_ERR_RUNTIME_NOT_INITIALIZED"
readonly FS_ERR_RUNTIME_ALREADY_INITIALIZED="FS_ERR_RUNTIME_ALREADY_INITIALIZED"
readonly FS_ERR_ALREADY_RUNNING="FS_ERR_ALREADY_RUNNING"
readonly FS_ERR_NOT_RUNNING="FS_ERR_NOT_RUNNING"
readonly FS_ERR_LOCK_EXISTS="FS_ERR_LOCK_EXISTS"
readonly FS_ERR_LOCK_FAILED="FS_ERR_LOCK_FAILED"

###############################################################################
# Service Errors
###############################################################################

readonly FS_ERR_SERVICE_NOT_FOUND="FS_ERR_SERVICE_NOT_FOUND"
readonly FS_ERR_SERVICE_ALREADY_EXISTS="FS_ERR_SERVICE_ALREADY_EXISTS"
readonly FS_ERR_SERVICE_START_FAILED="FS_ERR_SERVICE_START_FAILED"
readonly FS_ERR_SERVICE_STOP_FAILED="FS_ERR_SERVICE_STOP_FAILED"
readonly FS_ERR_SERVICE_RESTART_FAILED="FS_ERR_SERVICE_RESTART_FAILED"

###############################################################################
# Dependency Errors
###############################################################################

readonly FS_ERR_DEPENDENCY_MISSING="FS_ERR_DEPENDENCY_MISSING"
readonly FS_ERR_STORAGE_NOT_AVAILABLE="FS_ERR_STORAGE_NOT_AVAILABLE"
readonly FS_ERR_UNSUPPORTED_ENVIRONMENT="FS_ERR_UNSUPPORTED_ENVIRONMENT"

###############################################################################
# Synchronization Errors
###############################################################################

readonly FS_ERR_SYNC_FAILED="FS_ERR_SYNC_FAILED"
readonly FS_ERR_RSYNC_FAILED="FS_ERR_RSYNC_FAILED"
readonly FS_ERR_WATCHER_FAILED="FS_ERR_WATCHER_FAILED"
readonly FS_ERR_CONFLICT_DETECTED="FS_ERR_CONFLICT_DETECTED"

###############################################################################
# Validation Errors
###############################################################################

readonly FS_ERR_VALIDATION_FAILED="FS_ERR_VALIDATION_FAILED"

###############################################################################
# End of File
###############################################################################