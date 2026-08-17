#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/services/service-generator.sh
#
# Description:
#   Termux runit service management.
#
# Responsibilities:
#   • Generate FolderSynka services
#   • Remove FolderSynka services
#   • Start services
#   • Stop services
#   • Restart services
#   • Check service status
#   • List generated services
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/config/profile.sh"
source "${FS_HOME}/core/config/state.sh"

source "${FS_HOME}/core/utils/logger.sh"

###############################################################################
# Service Paths
###############################################################################

fs_service_directory() {
    local profile="$1"

    printf '%s\n' \
        "${PREFIX}/var/service/$(fs_service_name "$profile")"
}

fs_service_run_file() {
    local profile="$1"

    printf '%s\n' \
        "$(fs_service_directory "$profile")/run"
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

    local service_dir
    local run_file

    service_dir="$(fs_service_directory "$profile")"
    run_file="$(fs_service_run_file "$profile")"

    if fs_service_exists "$profile"; then
        fs_log_debug \
            "Service already exists: $(fs_service_name "$profile")"

        return 0
    fi

    mkdir -p "$service_dir"

    cat > "$run_file" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

exec foldersynka engine run "$profile"
EOF

    chmod +x "$run_file"

    fs_log_info \
        "Created service: $(fs_service_name "$profile")"
}

###############################################################################
# Remove Service
###############################################################################

fs_service_remove() {
    local profile="$1"

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

    fs_service_create "$profile"

    sv up "$(fs_service_name "$profile")"

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

    if ! fs_service_exists "$profile"; then
        return 0
    fi

    sv down "$(fs_service_name "$profile")" || true

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

    fs_service_stop "$profile"

    sleep 1

    fs_service_start "$profile"
}

###############################################################################
# Service Status
###############################################################################

fs_service_status() {
    local profile="$1"

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

    if ! fs_service_exists "$profile"; then
        return 1
    fi

    sv status "$(fs_service_name "$profile")" >/dev/null 2>&1
}

###############################################################################
# List Services
###############################################################################

fs_service_list() {
    local directory="${PREFIX}/var/service"
    local service

    [[ -d "$directory" ]] || return 0

    for service in "$directory"/foldersynka-*; do
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