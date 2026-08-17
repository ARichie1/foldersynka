#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
#
# FolderSynka
#
# File:
#   core/utils/filesystem.sh
#
# Description:
#   Filesystem utility library.
#
# Responsibilities:
#   • Path normalization
#   • Filesystem checks
#   • Safe path validation
#   • File and directory operations
#   • Protected path detection
#
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/paths.sh"
source "${FS_HOME}/core/utils/terminal.sh"

###############################################################################
# Protected Paths
###############################################################################

readonly FS_PROTECTED_PATHS=(
    "/"
    "/system"
    "/vendor"
    "/product"
    "/proc"
    "/sys"
    "/dev"
    "/data"
    "$HOME"
    "$PREFIX"
)

###############################################################################
# Path Helpers
###############################################################################

fs_absolute_path() {
    local path="$1"

    if command -v realpath >/dev/null 2>&1; then
        realpath -m "$path"
        return 0
    fi

    readlink -f "$path"
}

fs_expand_path() {
    local path="$1"

    case "$path" in
        "~")
            printf "%s\n" "$HOME"
            ;;
        "~/"*)
            printf "%s/%s\n" "$HOME" "${path#~/}"
            ;;
        *)
            printf "%s\n" "$path"
            ;;
    esac
}

fs_normalize_path() {
    local path

    path="$(fs_expand_path "$1")"
    fs_absolute_path "$path"
}

###############################################################################
# Validation
###############################################################################

fs_validate_path() {
    [[ -n "$1" ]]
}

fs_file_exists() {
    [[ -f "$1" ]]
}

fs_directory_exists() {
    [[ -d "$1" ]]
}

fs_exists() {
    [[ -e "$1" ]]
}

###############################################################################
# Protected Paths
###############################################################################

fs_is_protected_path() {
    local path
    local protected

    path="$(fs_normalize_path "$1")"

    for protected in "${FS_PROTECTED_PATHS[@]}"; do
        protected="$(fs_normalize_path "$protected")"

        if [[ "$path" == "$protected" ]]; then
            return 0
        fi
    done

    return 1
}

fs_require_safe_path() {
    local path="$1"

    if ! fs_validate_path "$path"; then
        fs_print_error "Empty filesystem path."
        return 1
    fi

    if fs_is_protected_path "$path"; then
        fs_print_error "Refusing unsafe filesystem operation: $path"
        return 1
    fi
}

###############################################################################
# Permissions
###############################################################################

fs_is_readable() {
    [[ -r "$1" ]]
}

fs_is_writable() {
    [[ -w "$1" ]]
}

fs_is_executable() {
    [[ -x "$1" ]]
}

###############################################################################
# Parent / Filename Helpers
###############################################################################

fs_parent_directory() {
    dirname "$1"
}

fs_filename() {
    basename "$1"
}

fs_extension() {
    local file

    file="$(basename "$1")"
    printf "%s\n" "${file##*.}"
}

###############################################################################
# Path Information
###############################################################################

fs_path_info() {
    local path="$1"

    printf "Path       : %s\n" "$path"
    printf "Absolute   : %s\n" "$(fs_normalize_path "$path")"
    printf "Exists     : %s\n" \
        "$(fs_exists "$path" && echo yes || echo no)"
    printf "Readable   : %s\n" \
        "$(fs_is_readable "$path" && echo yes || echo no)"
    printf "Writable   : %s\n" \
        "$(fs_is_writable "$path" && echo yes || echo no)"
}

###############################################################################
# Directory Validation
###############################################################################

fs_validate_source_directory() {
    local source="$1"

    if ! fs_directory_exists "$source"; then
        fs_print_error "Source directory not found: $source"
        return 1
    fi

    if ! fs_is_readable "$source"; then
        fs_print_error "Source directory is not readable: $source"
        return 1
    fi
}

fs_validate_destination_directory() {
    local destination="$1"

    fs_require_safe_path "$destination" || return 1
}

###############################################################################
# Directory Operations
###############################################################################

fs_create_directory() {
    local directory="$1"

    fs_validate_path "$directory" || return 1
    mkdir -p "$directory"
}

fs_create_directory_safe() {
    local directory="$1"

    fs_require_safe_path "$directory" || return 1
    fs_create_directory "$directory"
}

###############################################################################
# File Operations
###############################################################################

fs_create_file() {
    local file="$1"

    fs_validate_path "$file" || return 1

    mkdir -p "$(dirname "$file")"
    touch "$file"
}

fs_create_file_safe() {
    local file="$1"

    fs_require_safe_path "$file" || return 1
    fs_create_file "$file"
}

###############################################################################
# Remove Operations
###############################################################################

fs_remove_file_safe() {
    local file="$1"

    fs_require_safe_path "$file" || return 1

    [[ -f "$file" ]] || return 0

    rm -f "$file"
}

fs_remove_directory_safe() {
    local directory="$1"

    fs_require_safe_path "$directory" || return 1

    [[ -d "$directory" ]] || return 0

    rm -rf "$directory"
}

###############################################################################
# Copy Operations
###############################################################################

fs_copy_file_safe() {
    local source="$1"
    local destination="$2"

    if ! fs_file_exists "$source"; then
        fs_print_error "Source file not found: $source"
        return 1
    fi

    fs_require_safe_path "$destination" || return 1

    mkdir -p "$(dirname "$destination")"
    cp "$source" "$destination"
}

fs_copy_directory_safe() {
    local source="$1"
    local destination="$2"

    if ! fs_directory_exists "$source"; then
        fs_print_error "Source directory not found: $source"
        return 1
    fi

    fs_require_safe_path "$destination" || return 1

    mkdir -p "$destination"
    cp -R "$source"/. "$destination"
}

###############################################################################
# Move Operations
###############################################################################

fs_move_safe() {
    local source="$1"
    local destination="$2"

    if ! fs_exists "$source"; then
        fs_print_error "Source does not exist: $source"
        return 1
    fi

    fs_require_safe_path "$destination" || return 1

    mkdir -p "$(dirname "$destination")"
    mv "$source" "$destination"
}

fs_rename_safe() {
    local source="$1"
    local new_name="$2"
    local parent

    fs_exists "$source" || return 1

    parent="$(dirname "$source")"

    fs_move_safe "$source" "$parent/$new_name"
}

###############################################################################
# Write Operations
###############################################################################

fs_write_file() {
    local file="$1"

    shift

    fs_require_safe_path "$file" || return 1

    mkdir -p "$(dirname "$file")"
    printf "%s\n" "$*" > "$file"
}

fs_append_file() {
    local file="$1"

    shift

    fs_require_safe_path "$file" || return 1

    mkdir -p "$(dirname "$file")"
    printf "%s\n" "$*" >> "$file"
}

fs_touch() {
    local file="$1"

    fs_require_safe_path "$file" || return 1

    mkdir -p "$(dirname "$file")"
    touch "$file"
}

###############################################################################
# Permissions
###############################################################################

fs_make_executable() {
    chmod +x "$1"
}

fs_make_readonly() {
    chmod 444 "$1"
}

fs_make_writable() {
    chmod u+w "$1"
}

###############################################################################
# Atomic Writes
###############################################################################

fs_write_atomic() {
    local destination="$1"
    local temporary

    shift

    fs_require_safe_path "$destination" || return 1

    temporary="${destination}.tmp.$$"

    mkdir -p "$(dirname "$destination")"

    printf "%s\n" "$*" > "$temporary"
    mv "$temporary" "$destination"
}

###############################################################################
# Directory Cleanup
###############################################################################

fs_clear_directory_safe() {
    local directory="$1"

    fs_require_safe_path "$directory" || return 1

    [[ -d "$directory" ]] || return 0

    find "$directory" -mindepth 1 -delete
}

fs_cleanup_empty_directories() {
    local directory="$1"

    find "$directory" \
        -type d \
        -empty \
        -delete
}

###############################################################################
# Empty Checks
###############################################################################

fs_directory_empty() {
    [[ -d "$1" ]] || return 1
    [[ -z "$(find "$1" -mindepth 1 -print -quit 2>/dev/null)" ]]
}

fs_file_empty() {
    [[ -f "$1" ]] || return 1
    [[ ! -s "$1" ]]
}

###############################################################################
# Read Operations
###############################################################################

fs_read_file() {
    local file="$1"

    fs_file_exists "$file" || return 1

    cat "$file"
}

fs_read_lines() {
    local file="$1"

    fs_file_exists "$file" || return 1

    mapfile -t FS_LINES < "$file"
}

###############################################################################
# Search
###############################################################################

fs_find_files() {
    local directory="$1"
    local pattern="${2:-*}"

    find "$directory" \
        -type f \
        -name "$pattern"
}

fs_find_directories() {
    local directory="$1"
    local pattern="${2:-*}"

    find "$directory" \
        -type d \
        -name "$pattern"
}

###############################################################################
# Symbolic Links
###############################################################################

fs_create_symlink() {
    local source="$1"
    local destination="$2"

    fs_require_safe_path "$destination" || return 1

    mkdir -p "$(dirname "$destination")"
    ln -sfn "$source" "$destination"
}

fs_remove_symlink() {
    local link="$1"

    [[ -L "$link" ]] || return 0

    rm -f "$link"
}

###############################################################################
# Temporary Files
###############################################################################

fs_temp_file() {
    mktemp "${TMPDIR:-/tmp}/foldersynka.XXXXXX"
}

fs_temp_directory() {
    mktemp -d "${TMPDIR:-/tmp}/foldersynka.XXXXXX"
}

###############################################################################
# Directory Listing
###############################################################################

fs_list_files() {
    local directory="$1"

    ls -A "$directory"
}

###############################################################################
# File Metadata
###############################################################################

fs_file_size() {
    stat -c "%s" "$1"
}

fs_directory_size() {
    du -sb "$1" | cut -f1
}

fs_last_modified() {
    stat -c "%Y" "$1"
}

###############################################################################
# Checksums
###############################################################################

fs_sha256() {
    sha256sum "$1" | cut -d' ' -f1
}

###############################################################################
# Diagnostics
###############################################################################

fs_print_info() {
    local path="$1"

    printf "Path          : %s\n" "$path"
    printf "Absolute      : %s\n" "$(fs_normalize_path "$path")"
    printf "Exists        : %s\n" \
        "$(fs_exists "$path" && echo yes || echo no)"
    printf "Readable      : %s\n" \
        "$(fs_is_readable "$path" && echo yes || echo no)"
    printf "Writable      : %s\n" \
        "$(fs_is_writable "$path" && echo yes || echo no)"
    printf "Executable    : %s\n" \
        "$(fs_is_executable "$path" && echo yes || echo no)"

    if fs_exists "$path"; then
        printf "Size          : %s\n" \
            "$(fs_file_size "$path" 2>/dev/null || echo "-")"
    fi
}

fs_self_test() {
    fs_print_info "$HOME"

    fs_print_key_value "HOME" "$HOME"
    fs_print_key_value "PREFIX" "$PREFIX"
    fs_print_key_value "TMPDIR" "${TMPDIR:-/tmp}"
    fs_print_key_value \
        "Writable HOME" \
        "$(fs_is_writable "$HOME" && echo yes || echo no)"
}

###############################################################################
# End of File
###############################################################################