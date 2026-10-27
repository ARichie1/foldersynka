#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/services/service-generator.sh
#
# Description:
#   Termux/runit service lifecycle management.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/utils/logger.sh"
source "${FS_HOME}/core/utils/validation.sh"

###############################################################################
# Service Paths
###############################################################################

fs_service_directory() {
    local profile="$1"

    fs_termux_service_dir "$profile"
}

fs_service_run_file() {
    local profile="$1"

    printf '%s/run\n' "$(fs_service_directory "$profile")"
}

###############################################################################
# Service Existence
###############################################################################

fs_service_exists() {
    local profile="$1"

    [[ -d "$(fs_service_directory "$profile")" ]]
}

###############################################################################
# Create Service
###############################################################################

fs_service_create() {
    local profile="$1"

    fs_validate_profile_name "$profile" || return 1
    fs_validate_profile_exists "$profile" || return 1

    local service_dir
    local run_file

    service_dir="$(fs_service_directory "$profile")"
    run_file="$(fs_service_run_file "$profile")"

    if fs_service_exists "$profile"; then
        return 0
    fi

    mkdir -p "$service_dir"

    local quoted_home
    printf -v quoted_home '%q' "$FS_HOME"
    cat > "$run_file" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export FS_HOME=${quoted_home}

source "\${FS_HOME}/core/config/config.sh"
source "\${FS_HOME}/core/engine/sync-engine.sh"

fs_sync_daemon "$profile"
EOF

    chmod 755 "$run_file"

    fs_log_info \
        "Created service: $(fs_service_name "$profile")"
}

###############################################################################
# Remove Service
###############################################################################

fs_service_remove() {
    local profile="$1"

    fs_validate_profile_name "$profile" || return 1

    local service_dir
    service_dir="$(fs_service_directory "$profile")"

    if ! fs_service_exists "$profile"; then
        return 0
    fi

    fs_service_stop "$profile" || true
    rm -rf -- "$service_dir"

    fs_log_info \
        "Removed service: $(fs_service_name "$profile")"
}

###############################################################################
# Start Service
###############################################################################

fs_service_start() {
    local profile="$1"

    fs_validate_environment || return 1
    fs_validate_termux_services || return 1
    fs_validate_profile_name "$profile" || return 1
    fs_validate_profile_exists "$profile" || return 1

    fs_service_create "$profile"

    if ! sv up "$(fs_service_name "$profile")"; then
        fs_log_error \
            "Unable to start service: $(fs_service_name "$profile")"
        return 1
    fi

    fs_state_service_write \
        "$profile" \
        "running"

    fs_log_info \
        "Started service: $(fs_service_name "$profile")"
}

###############################################################################
# Stop Service
###############################################################################

fs_service_stop() {
    local profile="$1"

    fs_validate_profile_name "$profile" || return 1

    if ! fs_service_exists "$profile"; then
        return 0
    fi

    if ! sv down "$(fs_service_name "$profile")"; then
        fs_log_error \
            "Unable to stop service: $(fs_service_name "$profile")"
        return 1
    fi

    fs_state_service_write \
        "$profile" \
        "stopped"

    fs_log_info \
        "Stopped service: $(fs_service_name "$profile")"
}

###############################################################################
# Restart Service
###############################################################################

fs_service_restart() {
    local profile="$1"

    fs_service_stop "$profile" || return 1
    fs_service_start "$profile"
}

###############################################################################
# Service Status
###############################################################################

fs_service_status() {
    local profile="$1"

    fs_validate_profile_name "$profile" || return 1

    if ! fs_service_exists "$profile"; then
        printf '%s\n' "not-created"
        return 0
    fi

    sv status "$(fs_service_name "$profile")"
}

###############################################################################
# Service Running
###############################################################################

fs_service_running() {
    local profile="$1"

    fs_service_exists "$profile" || return 1
    local result
    result=$(sv status "$(fs_service_name "$profile")" 2>/dev/null) || return 1
    # Real runit status returns success for a supervised service that is down.
    [[ "$result" == run:* ]] && return 0
    [[ -z "$result" ]] || return 1
    # The portable test supervisor reports only an exit code.
    return 0
}

###############################################################################
# List Services
###############################################################################

fs_service_list() {
    local directory="$FS_TERMUX_SERVICE_DIR"
    local service

    [[ -d "$directory" ]] || return 0

    for service in "$directory"/"${FS_SERVICE_PREFIX}"-*; do
        [[ -e "$service" ]] || continue
        basename "$service"
    done
}

###############################################################################
# Service Information
###############################################################################

fs_service_info() {
    local profile="$1"

    printf 'Service\n'
    printf 'Name    : %s\n' "$(fs_service_name "$profile")"
    printf 'Path    : %s\n' "$(fs_service_directory "$profile")"
    printf 'Status  : '

    if ! fs_service_exists "$profile"; then
        printf '%s\n' "not-created"
        return 0
    fi

    if fs_service_running "$profile"; then
        printf '%s\n' "running"
    else
        printf '%s\n' "stopped"
    fi
}

###############################################################################
# End of File
###############################################################################
