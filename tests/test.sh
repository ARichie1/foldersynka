#!/usr/bin/env bash

set -euo pipefail

TEST_ROOT="$(mktemp -d)"
TEST_HOME="${TEST_ROOT}/home"
TEST_PREFIX="${TEST_ROOT}/prefix"
TEST_BIN="${TEST_ROOT}/bin"
TEST_SOURCE="${TEST_HOME}/source"
TEST_DEST="${TEST_HOME}/destination"
TEST_STORAGE="${TEST_HOME}/storage/shared"
TEST_SV_STATE="${TEST_ROOT}/sv-state"

mkdir -p \
    "$TEST_HOME" \
    "$TEST_PREFIX" \
    "$TEST_BIN" \
    "$TEST_SOURCE" \
    "$TEST_DEST" \
    "$TEST_STORAGE" \
    "$TEST_SV_STATE"

cleanup() {
    pkill -TERM -f "$TEST_ROOT" 2>/dev/null || true
    sleep 0.1
    pkill -KILL -f "$TEST_ROOT" 2>/dev/null || true
    rm -rf "$TEST_ROOT"
}

trap cleanup EXIT

cat > "$TEST_BIN/sv" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

action="$1"
name="$2"
service_dir="${PREFIX}/var/service/${name}"
state_dir="${TEST_SV_STATE}"
pid_file="${state_dir}/${name}.pid"
log_file="${state_dir}/${name}.log"

case "$action" in
    up)
        bash "${service_dir}/run" >"$log_file" 2>&1 &
        printf '%s\n' "$!" >"$pid_file"
        ;;

    down)
        if [[ -f "$pid_file" ]]; then
            pid="$(<"$pid_file")"
            kill -TERM "$pid" 2>/dev/null || true

            for _ in {1..50}; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    break
                fi
                sleep 0.05
            done

            kill -KILL "$pid" 2>/dev/null || true
            rm -f "$pid_file"
        fi
        ;;

    status)
        if [[ -f "$pid_file" ]] &&
            kill -0 "$(cat "$pid_file")" 2>/dev/null
        then
            exit 0
        fi

        exit 1
        ;;

    *)
        exit 1
        ;;
esac
EOF

chmod 755 "$TEST_BIN/sv"

export HOME="$TEST_HOME"
export PREFIX="$TEST_PREFIX"
export FS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TEST_SV_STATE="$TEST_SV_STATE"
export PATH="$TEST_BIN:$PATH"
export TERM="${TERM:-xterm}"

CLI="${FS_HOME}/core/cli/router.sh"

pass=0
fail=0

assert_success() {
    local name="$1"
    shift

    if "$@"; then
        printf 'PASS: %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL: %s\n' "$name" >&2
        fail=$((fail + 1))
    fi
}

assert_failure() {
    local name="$1"
    shift

    if ! "$@" >/dev/null 2>&1; then
        printf 'PASS: %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL: %s\n' "$name" >&2
        fail=$((fail + 1))
    fi
}

assert_contains() {
    local name="$1"
    local expected="$2"
    shift 2

    local output
    output="$("$@")"

    if [[ "$output" == *"$expected"* ]]; then
        printf 'PASS: %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL: %s\n' "$name" >&2
        printf 'Expected: %s\n' "$expected" >&2
        printf 'Output: %s\n' "$output" >&2
        fail=$((fail + 1))
    fi
}

assert_file_contains() {
    local name="$1"
    local file="$2"
    local expected="$3"

    if [[ -f "$file" ]] && grep -Fqx -- "$expected" "$file"; then
        printf 'PASS: %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL: %s\n' "$name" >&2
        fail=$((fail + 1))
    fi
}

printf '\nFolderSynka integration tests\n\n'

assert_contains \
    "version command" \
    "FolderSynka v1.0.0" \
    bash "$CLI" --version

assert_success \
    "help command" \
    bash "$CLI" --help

assert_failure \
    "invalid command rejected" \
    bash "$CLI" does-not-exist

assert_failure \
    "invalid create arguments rejected" \
    bash "$CLI" create

assert_success \
    "profile creation" \
    bash "$CLI" create demo --src "$TEST_SOURCE" --dest "$TEST_DEST" --no-delete --checksum

assert_file_contains \
    "ignore file created" \
    "${TEST_SOURCE}/.foldersynkaignore" \
    ".git/"

assert_file_contains \
    "checksum option persisted" \
    "${TEST_HOME}/.foldersynka/configs/demo.conf" \
    'CHECKSUM="true"'

assert_file_contains \
    "delete option persisted" \
    "${TEST_HOME}/.foldersynka/configs/demo.conf" \
    'DELETE="false"'

assert_success \
    "profile listed" \
    bash "$CLI" list

assert_success \
    "profile status" \
    bash "$CLI" status demo

assert_success \
    "doctor" \
    bash "$CLI" doctor

assert_success \
    "ignore add" \
    bash "$CLI" ignore demo add "test-output/"

assert_success \
    "ignore list" \
    bash "$CLI" ignore demo list

assert_success \
    "ignore exists" \
    bash -c 'source "$FS_HOME/core/config/config.sh"; source "$FS_HOME/core/config/profile.sh"; source "$FS_HOME/core/config/ignore.sh"; fs_ignore_exists demo'

assert_success \
    "ignore read" \
    bash -c 'source "$FS_HOME/core/config/config.sh"; source "$FS_HOME/core/config/profile.sh"; source "$FS_HOME/core/config/ignore.sh"; fs_ignore_read demo'

assert_success \
    "ignore validate" \
    bash -c 'source "$FS_HOME/core/config/config.sh"; source "$FS_HOME/core/config/profile.sh"; source "$FS_HOME/core/config/ignore.sh"; fs_ignore_validate demo'

assert_success \
    "ignore pattern matching" \
    bash -c 'source "$FS_HOME/core/config/config.sh"; source "$FS_HOME/core/config/profile.sh"; source "$FS_HOME/core/config/ignore.sh"; fs_ignore_add demo "test-output/"; fs_ignore_is_ignored demo "test-output/file.txt"'

assert_file_contains \
    "ignore rule persisted" \
    "${TEST_SOURCE}/.foldersynkaignore" \
    "test-output/"

assert_success \
    "ignore remove" \
    bash "$CLI" ignore demo remove "test-output/"

assert_success \
    "ignore reset" \
    bash "$CLI" ignore demo reset

assert_file_contains \
    "ignore reset restored template" \
    "${TEST_SOURCE}/.foldersynkaignore" \
    ".git/"

printf 'Running synchronization lifecycle...\n'

printf 'initial\n' > "${TEST_SOURCE}/hello.txt"

assert_success \
    "service start" \
    bash "$CLI" start demo

for _ in {1..50}; do
    [[ -f "${TEST_DEST}/hello.txt" ]] && break
    sleep 0.1
done

if [[ -f "${TEST_DEST}/hello.txt" ]] &&
    [[ "$(<"${TEST_DEST}/hello.txt")" == "initial" ]]
then
    printf 'PASS: initial synchronization\n'
    pass=$((pass + 1))
else
    printf 'FAIL: initial synchronization\n' >&2
    fail=$((fail + 1))
fi

sleep 1

printf 'changed\n' > "${TEST_SOURCE}/hello.txt"

for _ in {1..80}; do
    [[ -f "${TEST_DEST}/hello.txt" ]] &&
        [[ "$(<"${TEST_DEST}/hello.txt")" == "changed" ]] &&
        break
    sleep 0.1
done

if [[ -f "${TEST_DEST}/hello.txt" ]] &&
    [[ "$(<"${TEST_DEST}/hello.txt")" == "changed" ]]
then
    printf 'PASS: watcher synchronization\n'
    pass=$((pass + 1))
else
    printf 'FAIL: watcher synchronization\n' >&2
    fail=$((fail + 1))
fi

for _ in {1..50}; do
    if grep -q '^STATUS="running"$'         "${TEST_HOME}/.foldersynka/state/demo/runtime.conf"
    then
        break
    fi
    sleep 0.1
done

assert_success \
    "service status" \
    bash "$CLI" status demo

assert_success \
    "service restart" \
    bash "$CLI" restart demo

sleep 0.2

assert_success \
    "service status after restart" \
    bash "$CLI" status demo

assert_success \
    "service stop" \
    bash "$CLI" stop demo

if [[ ! -f "${TEST_SV_STATE}/foldersynka-demo.pid" ]]; then
    printf 'PASS: service process stopped\n'
    pass=$((pass + 1))
else
    printf 'FAIL: service process stopped\n' >&2
    fail=$((fail + 1))
fi

assert_success \
    "profile removal" \
    bash "$CLI" remove demo

if [[ ! -f "${TEST_HOME}/.foldersynka/configs/demo.conf" ]]; then
    printf 'PASS: profile configuration removed\n'
    pass=$((pass + 1))
else
    printf 'FAIL: profile configuration removed\n' >&2
    fail=$((fail + 1))
fi

printf '\nResults: %d passed, %d failed\n' "$pass" "$fail"

if (( fail > 0 )); then
    exit 1
fi
