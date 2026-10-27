#!/usr/bin/env bash
set -euo pipefail
export FS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
safety_root=$(mktemp -d)
trap 'rm -rf -- "$safety_root"' EXIT
export HOME="$safety_root/home" PREFIX="$safety_root/prefix"
mkdir -p "$HOME" "$PREFIX" "$safety_root/source" "$safety_root/dest"
source "$FS_HOME/core/config/config.sh"
source "$FS_HOME/core/utils/validation.sh"
pass=0
check() { if "$@"; then pass=$((pass+1)); else printf 'FAIL: %s\n' "$*" >&2; exit 1; fi; }
reject() { if "$@"; then printf 'Unexpected success: %s\n' "$*" >&2; return 1; fi; }
source_path="$safety_root/"'literal $(touch PWNED) `touch PWNED` " '\'' \ | & ü'
mkdir -p "$source_path"
check fs_profile_create safe "$source_path" "$safety_root/dest"
check fs_profile_load safe
check test "$FS_PROFILE_SOURCE" = "$source_path"
check test "$FS_PROFILE_DELETE" = false
check test "$FS_PROFILE_MODE" = copy
check test ! -e PWNED
value=$'literal $(touch PWNED) `touch PWNED` " \' \\ | & ü\nsecond line'
check fs_profile_set safe LOG_FILE "$value"
check fs_profile_load safe
check test "$FS_PROFILE_LOG_FILE" = "$value"
check fs_profile_set safe CHECKSUM true
check grep -q '^CHECKSUM="true"$' "$(fs_profile_config_file safe)"
check fs_profile_set safe DELETE false
check grep -q '^DELETE="false"$' "$(fs_profile_config_file safe)"
for mode in copy mirror bidirectional; do
    check fs_profile_set safe MODE "$mode"
    check test "$(fs_profile_get safe MODE)" = "$mode"
done
check reject fs_profile_set safe MODE invalid
check reject fs_profile_set safe DELETE '$(touch PWNED)'
# Legacy files have no MODE and retain their deletion semantics.
sed '/^MODE=/d; s/^DELETE=.*/DELETE="true"/' "$(fs_profile_config_file safe)" > "$safety_root/legacy"
mv "$safety_root/legacy" "$(fs_profile_config_file safe)"
check fs_profile_load safe
check test "$FS_PROFILE_MODE" = mirror
check fs_profile_set safe DELETE false
check fs_profile_load safe
check test "$FS_PROFILE_MODE" = copy
check fs_state_init safe
check fs_state_load safe
FS_STATE_LAST_ERROR=$value
check fs_state_commit safe
check fs_state_load safe
check test "$FS_STATE_LAST_ERROR" = "$value"
check test "$(stat -c %a "$(fs_state_file safe)")" = 600
check test "$(stat -c %a "$(fs_profile_config_file safe)")" = 600
for pair in equal child parent alias root; do
    case "$pair" in
        equal) a="$source_path"; b="$source_path/." ;;
        child) a="$safety_root/source"; b="$a/child" ;;
        parent) b="$safety_root/source"; a="$b/child" ;;
        alias) ln -s "$safety_root/source" "$safety_root/alias"; a="$safety_root/source"; b="$safety_root/alias" ;;
        root) a=/; b="$safety_root/dest" ;;
    esac
    check reject fs_validate_sync_paths "$a" "$b"
    check reject fs_profile_create "bad_$pair" "$a" "$b"
done
check fs_state_lock_acquire safe
check reject fs_state_lock_acquire safe
check bash -c 'source "$FS_HOME/core/config/state.sh"; fs_state_lock_release safe'
check fs_state_lock_exists safe
check fs_state_lock_release safe
printf '999999999:stale\n' > "$(fs_profile_lock_file safe)"
if command -v flock >/dev/null; then
    check fs_state_lock_acquire safe
    check fs_state_lock_release safe
fi
# Loading rechecks aliases after a profile was created.
check fs_profile_create moving "$safety_root/source" "$safety_root/dest"
rmdir "$safety_root/dest"
ln -s "$safety_root/source" "$safety_root/dest"
check reject fs_profile_load moving
rm "$safety_root/dest"
mkdir "$safety_root/dest"
check reject fs_validate_path_pair /proc/self "$safety_root/dest"
check fs_state_load safe
FS_STATE_FILES_SYNCED='1+2'
check reject fs_state_commit safe
check fs_state_load safe
check test "$FS_STATE_FILES_SYNCED" = 0
# Existing unsafe shell source must fail without executing its contents.
printf 'LAST_ERROR="$(touch PWNED)"\n' > "$(fs_state_file safe)"
check reject fs_state_load safe
printf 'SOURCE="$(touch PWNED)"\n' >> "$(fs_profile_config_file safe)"
check reject fs_profile_load safe
check test ! -e PWNED
printf 'Safety tests: %s passed\n' "$pass"
