#!/usr/bin/env bash
# Public JSON protocol. Only the canonical shell loader reads profiles.
set -euo pipefail
command -v python3 >/dev/null || { printf '%s\n' '{"schemaVersion":1,"ok":false,"error":{"code":"DEPENDENCY_MISSING","message":"python3 required"}}'; exit 2; }
operation="${1:-capabilities}"
shift || true
if [[ "$operation" != capabilities ]]; then
    source "${FS_HOME}/core/config/profile.sh"
    profile="${1:-}"
    if ! fs_profile_validate_name "$profile" || ! fs_profile_load "$profile" >&2; then
        printf '%s\n' '{"schemaVersion":1,"ok":false,"error":{"code":"INVALID_PROFILE"}}'
        exit 2
    fi
    export FS_PROFILE_MODE="${FS_PROFILE_MODE:-copy}"
    export FS_RECONCILE_STATE="$(fs_profile_state_dir "$profile")/reconcile"
    export FS_RECONCILE_IGNORE="${FS_PROFILE_SOURCE}/${FS_PROFILE_IGNORE_FILE:-.foldersynkaignore}"
fi
exec python3 "${FS_HOME}/core/engine/reconcile.py" "$operation" "$@"
