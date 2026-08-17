#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/lib/error-registry.sh
#
# Description:
#   Central registry mapping application errors to metadata.
#
# Responsibilities:
#   • Map error codes to messages
#   • Map errors to process exit codes
#   • Define error severity
#   • Define user-facing hints
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/lib/error-codes.sh"
source "${FS_HOME}/core/lib/exit-codes.sh"

###############################################################################
# Registry
###############################################################################

declare -gA FS_ERROR_MESSAGES=()
declare -gA FS_ERROR_EXIT_CODES=()
declare -gA FS_ERROR_SEVERITIES=()
declare -gA FS_ERROR_HINTS=()

###############################################################################
# Registration
###############################################################################

fs_register_error() {
    local code="$1"
    local exit_code="$2"
    local severity="$3"
    local message="$4"
    local hint="${5:-}"

    FS_ERROR_MESSAGES["$code"]="$message"
    FS_ERROR_EXIT_CODES["$code"]="$exit_code"
    FS_ERROR_SEVERITIES["$code"]="$severity"
    FS_ERROR_HINTS["$code"]="$hint"
}

###############################################################################
# Generic
###############################################################################

fs_register_error \
    "$FS_ERR_UNKNOWN" \
    "$FS_EXIT_UNKNOWN_ERROR" \
    "ERROR" \
    "Unknown application error." \
    "Please report this issue."

fs_register_error \
    "$FS_ERR_INTERNAL" \
    "$FS_EXIT_INTERNAL_ERROR" \
    "FATAL" \
    "Internal application error." \
    "Inspect the logs."

fs_register_error \
    "$FS_ERR_NOT_IMPLEMENTED" \
    "$FS_EXIT_NOT_IMPLEMENTED" \
    "ERROR" \
    "This feature is not implemented." \
    "Check the documentation for supported features."

fs_register_error \
    "$FS_ERR_INVALID_ARGUMENT" \
    "$FS_EXIT_INVALID_ARGUMENT" \
    "ERROR" \
    "Invalid argument." \
    "Check the command syntax."

fs_register_error \
    "$FS_ERR_INVALID_CONFIGURATION" \
    "$FS_EXIT_INVALID_CONFIGURATION" \
    "ERROR" \
    "Invalid configuration." \
    "Check the profile configuration."

###############################################################################
# Profile
###############################################################################

fs_register_error \
    "$FS_ERR_PROFILE_EXISTS" \
    "$FS_EXIT_PROFILE_EXISTS" \
    "ERROR" \
    "Profile already exists." \
    "Choose another profile name."

fs_register_error \
    "$FS_ERR_PROFILE_NOT_FOUND" \
    "$FS_EXIT_PROFILE_NOT_FOUND" \
    "ERROR" \
    "Profile not found." \
    "Run 'foldersynka list'."

fs_register_error \
    "$FS_ERR_PROFILE_CORRUPTED" \
    "$FS_EXIT_PROFILE_CORRUPTED" \
    "ERROR" \
    "Profile configuration is corrupted." \
    "Inspect or recreate the profile."

fs_register_error \
    "$FS_ERR_INVALID_PROFILE_NAME" \
    "$FS_EXIT_INVALID_PROFILE_NAME" \
    "ERROR" \
    "Invalid profile name." \
    "Use only letters, numbers, '.', '_' and '-'."

###############################################################################
# Source
###############################################################################

fs_register_error \
    "$FS_ERR_SOURCE_NOT_FOUND" \
    "$FS_EXIT_SOURCE_NOT_FOUND" \
    "ERROR" \
    "Source directory does not exist." \
    "Check the configured source path."

fs_register_error \
    "$FS_ERR_SOURCE_NOT_DIRECTORY" \
    "$FS_EXIT_INVALID_PATH" \
    "ERROR" \
    "Source path is not a directory." \
    "Provide a valid source directory."

fs_register_error \
    "$FS_ERR_SOURCE_NOT_READABLE" \
    "$FS_EXIT_SOURCE_NOT_READABLE" \
    "ERROR" \
    "Source directory cannot be read." \
    "Check filesystem permissions."

###############################################################################
# Destination
###############################################################################

fs_register_error \
    "$FS_ERR_DESTINATION_NOT_FOUND" \
    "$FS_EXIT_DESTINATION_NOT_FOUND" \
    "ERROR" \
    "Destination directory does not exist." \
    "Check the configured destination path."

fs_register_error \
    "$FS_ERR_DESTINATION_INVALID" \
    "$FS_EXIT_INVALID_PATH" \
    "ERROR" \
    "Destination path is invalid." \
    "Choose a valid destination directory."

fs_register_error \
    "$FS_ERR_DESTINATION_UNSAFE" \
    "$FS_EXIT_INVALID_PATH" \
    "ERROR" \
    "Destination path is unsafe." \
    "Choose a valid destination directory."

fs_register_error \
    "$FS_ERR_DESTINATION_PARENT_NOT_FOUND" \
    "$FS_EXIT_DESTINATION_NOT_FOUND" \
    "ERROR" \
    "Destination parent directory does not exist." \
    "Create the parent directory first."

fs_register_error \
    "$FS_ERR_DESTINATION_NOT_WRITABLE" \
    "$FS_EXIT_DESTINATION_NOT_WRITABLE" \
    "ERROR" \
    "Destination directory is not writable." \
    "Check filesystem permissions."

###############################################################################
# Filesystem
###############################################################################

fs_register_error \
    "$FS_ERR_PATH_INVALID" \
    "$FS_EXIT_INVALID_PATH" \
    "ERROR" \
    "Path is invalid." \
    "Provide a valid filesystem path."

fs_register_error \
    "$FS_ERR_PATH_PROTECTED" \
    "$FS_EXIT_PERMISSION_DENIED" \
    "ERROR" \
    "Path is protected." \
    "Choose a permitted location."

fs_register_error \
    "$FS_ERR_PERMISSION_DENIED" \
    "$FS_EXIT_PERMISSION_DENIED" \
    "ERROR" \
    "Permission denied." \
    "Check filesystem permissions."

fs_register_error \
    "$FS_ERR_FILESYSTEM" \
    "$FS_EXIT_FILESYSTEM_ERROR" \
    "ERROR" \
    "Filesystem operation failed." \
    "Inspect the filesystem and logs."

###############################################################################
# Ignore File
###############################################################################

fs_register_error \
    "$FS_ERR_IGNORE_FILE_NOT_FOUND" \
    "$FS_EXIT_VALIDATION_FAILED" \
    "ERROR" \
    "Ignore file was not found." \
    "Check the configured ignore file."

fs_register_error \
    "$FS_ERR_IGNORE_FILE_INVALID" \
    "$FS_EXIT_IGNORE_FILE_INVALID" \
    "ERROR" \
    "Ignore file is invalid." \
    "Check the .foldersynkaignore file."

fs_register_error \
    "$FS_ERR_IGNORE_FILE_NOT_READABLE" \
    "$FS_EXIT_PERMISSION_DENIED" \
    "ERROR" \
    "Ignore file cannot be read." \
    "Check file permissions."

###############################################################################
# Runtime
###############################################################################

fs_register_error \
    "$FS_ERR_RUNTIME_NOT_INITIALIZED" \
    "$FS_EXIT_RUNTIME_NOT_INITIALIZED" \
    "ERROR" \
    "Runtime has not been initialized." \
    "Initialize the profile runtime first."

fs_register_error \
    "$FS_ERR_RUNTIME_ALREADY_INITIALIZED" \
    "$FS_EXIT_RUNTIME_ALREADY_INITIALIZED" \
    "ERROR" \
    "Runtime is already initialized." \
    "Inspect the existing runtime state."

fs_register_error \
    "$FS_ERR_ALREADY_RUNNING" \
    "$FS_EXIT_ALREADY_RUNNING" \
    "ERROR" \
    "Profile is already running." \
    "Stop the profile before starting it again."

fs_register_error \
    "$FS_ERR_NOT_RUNNING" \
    "$FS_EXIT_NOT_RUNNING" \
    "ERROR" \
    "Profile is not running." \
    "Start the profile first."

fs_register_error \
    "$FS_ERR_LOCK_EXISTS" \
    "$FS_EXIT_LOCK_EXISTS" \
    "ERROR" \
    "A synchronization lock already exists." \
    "Wait for the current synchronization to finish."

fs_register_error \
    "$FS_ERR_LOCK_FAILED" \
    "$FS_EXIT_LOCK_FAILED" \
    "ERROR" \
    "Unable to acquire synchronization lock." \
    "Inspect the runtime state."

###############################################################################
# Services
###############################################################################

fs_register_error \
    "$FS_ERR_SERVICE_NOT_FOUND" \
    "$FS_EXIT_SERVICE_NOT_FOUND" \
    "ERROR" \
    "Service was not found." \
    "Create the service first."

fs_register_error \
    "$FS_ERR_SERVICE_ALREADY_EXISTS" \
    "$FS_EXIT_SERVICE_ALREADY_EXISTS" \
    "ERROR" \
    "Service already exists." \
    "Use the existing service or remove it first."

fs_register_error \
    "$FS_ERR_SERVICE_START_FAILED" \
    "$FS_EXIT_SERVICE_START_FAILED" \
    "ERROR" \
    "Service failed to start." \
    "Inspect the service status and logs."

fs_register_error \
    "$FS_ERR_SERVICE_STOP_FAILED" \
    "$FS_EXIT_SERVICE_STOP_FAILED" \
    "ERROR" \
    "Service failed to stop." \
    "Inspect the service status and logs."

fs_register_error \
    "$FS_ERR_SERVICE_RESTART_FAILED" \
    "$FS_EXIT_SERVICE_RESTART_FAILED" \
    "ERROR" \
    "Service failed to restart." \
    "Inspect the service status and logs."

###############################################################################
# Dependencies
###############################################################################

fs_register_error \
    "$FS_ERR_DEPENDENCY_MISSING" \
    "$FS_EXIT_DEPENDENCY_MISSING" \
    "FATAL" \
    "Required dependency is missing." \
    "Run 'foldersynka doctor'."

fs_register_error \
    "$FS_ERR_STORAGE_NOT_AVAILABLE" \
    "$FS_EXIT_STORAGE_NOT_AVAILABLE" \
    "ERROR" \
    "Android shared storage is unavailable." \
    "Run 'termux-setup-storage'."

fs_register_error \
    "$FS_ERR_UNSUPPORTED_ENVIRONMENT" \
    "$FS_EXIT_UNSUPPORTED_ENVIRONMENT" \
    "FATAL" \
    "The current environment is not supported." \
    "Run FolderSynka inside Termux."

###############################################################################
# Synchronization
###############################################################################

fs_register_error \
    "$FS_ERR_SYNC_FAILED" \
    "$FS_EXIT_SYNC_FAILED" \
    "ERROR" \
    "Synchronization failed." \
    "Inspect the log file."

fs_register_error \
    "$FS_ERR_RSYNC_FAILED" \
    "$FS_EXIT_RSYNC_FAILED" \
    "ERROR" \
    "Rsync synchronization failed." \
    "Inspect the rsync output and logs."

fs_register_error \
    "$FS_ERR_WATCHER_FAILED" \
    "$FS_EXIT_WATCHER_FAILED" \
    "ERROR" \
    "Filesystem watcher failed." \
    "Check that inotify-tools is installed."

fs_register_error \
    "$FS_ERR_CONFLICT_DETECTED" \
    "$FS_EXIT_SYNC_FAILED" \
    "ERROR" \
    "A synchronization conflict was detected." \
    "Inspect the affected files."

###############################################################################
# Validation
###############################################################################

fs_register_error \
    "$FS_ERR_VALIDATION_FAILED" \
    "$FS_EXIT_VALIDATION_FAILED" \
    "ERROR" \
    "Validation failed." \
    "Correct the reported configuration or filesystem issue."

###############################################################################
# End of File
###############################################################################