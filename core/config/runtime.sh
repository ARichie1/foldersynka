#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/config/runtime.sh
#
# Description:
#   Runtime environment manager.
#
# Responsibilities:
#   • Initialize runtime directories
#   • Verify runtime directories
#   • Ensure runtime is available
#   • Clear runtime cache
#   • Reset runtime environment
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"

###############################################################################
# Initialize Runtime
###############################################################################

fs_runtime_init() {

    mkdir -p \
        "$FS_RUNTIME_DIR" \
        "$FS_CONFIG_DIR" \
        "$FS_STATE_DIR" \
        "$FS_LOG_DIR" \
        "$FS_PID_DIR" \
        "$FS_LOCK_DIR" \
        "$FS_CACHE_DIR" \
        "$FS_SERVICE_DIR"

}

###############################################################################
# Runtime Exists
###############################################################################

fs_runtime_exists() {

    [[ -d "$FS_RUNTIME_DIR" ]]

}

###############################################################################
# Verify Runtime
###############################################################################

fs_runtime_verify() {

    local missing=0
    local directory

    for directory in \
        "$FS_RUNTIME_DIR" \
        "$FS_CONFIG_DIR" \
        "$FS_STATE_DIR" \
        "$FS_LOG_DIR" \
        "$FS_PID_DIR" \
        "$FS_LOCK_DIR" \
        "$FS_CACHE_DIR" \
        "$FS_SERVICE_DIR"
    do
        if [[ ! -d "$directory" ]]; then
            printf "Missing runtime directory: %s\n" "$directory"
            missing=1
        fi
    done

    return "$missing"

}

###############################################################################
# Ensure Runtime
###############################################################################

fs_runtime_ensure() {

    if fs_runtime_verify; then
        return 0
    fi

    fs_runtime_init

}

###############################################################################
# Clear Cache
###############################################################################

fs_runtime_clear_cache() {

    [[ -d "$FS_CACHE_DIR" ]] || return 0

    find "$FS_CACHE_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -exec rm -rf -- {} +

}

###############################################################################
# Reset Runtime
###############################################################################

fs_runtime_reset() {

    rm -rf -- "$FS_RUNTIME_DIR"

    fs_runtime_init

}

###############################################################################
# Runtime Information
###############################################################################

fs_runtime_info() {

    cat <<EOF
FolderSynka Runtime

Runtime Directory : $FS_RUNTIME_DIR
Config Directory  : $FS_CONFIG_DIR
State Directory   : $FS_STATE_DIR
Log Directory     : $FS_LOG_DIR
PID Directory     : $FS_PID_DIR
Lock Directory    : $FS_LOCK_DIR
Cache Directory   : $FS_CACHE_DIR
Service Directory : $FS_SERVICE_DIR
EOF

}

###############################################################################
# End of File
###############################################################################