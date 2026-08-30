#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/help.sh
#
# Description:
#   Displays FolderSynka CLI help.
###############################################################################

set -euo pipefail

###############################################################################
# Dependencies
###############################################################################

source "${FS_HOME}/core/config/config.sh"

###############################################################################
# Version
###############################################################################

FS_VERSION="development"

if [[ -f "${FS_HOME}/VERSION" ]]; then
    FS_VERSION="$(<"${FS_HOME}/VERSION")"
fi

TOPIC="${1:-general}"

###############################################################################
# General Help
###############################################################################

show_general_help() {

    cat <<EOF

FolderSynka v${FS_VERSION}

Developer-first workspace synchronization manager for Termux.

USAGE

    foldersynka <command> [options]

COMMANDS

    create      Create a new sync profile
    start       Start a sync service
    stop        Stop a sync service
    restart     Restart a sync service
    status      Show profile status
    list        List sync profiles
    remove      Remove a sync profile
    doctor      Diagnose the installation
    ignore      Manage .foldersynkaignore
    version     Show FolderSynka version

GLOBAL OPTIONS

    -h, --help
        Show help

    -v, --version
        Show version

EXAMPLES

    foldersynka create my-app \\
        --src ~/storage/shared/MyApp \\
        --dest ~/documents/MyApp

    foldersynka start my-app

    foldersynka status my-app

    foldersynka restart my-app

    foldersynka ignore my-app init

MORE HELP

    foldersynka help create
    foldersynka help start
    foldersynka help stop
    foldersynka help restart
    foldersynka help status
    foldersynka help remove
    foldersynka help doctor
    foldersynka help ignore

EOF

}

###############################################################################
# Create
###############################################################################

show_create_help() {

    cat <<EOF

foldersynka create

Create a new synchronization profile.

USAGE

    foldersynka create <profile> --src <source> --dest <destination>

OPTIONS

    --src, -s
        Source directory.

    --dest, -d
        Destination directory.

    --compress
        Enable rsync compression.

    --checksum
        Enable checksum comparison.

    --no-delete
        Disable deletion of removed files.

    --watch
        Start the profile after creation.

    -h, --help
        Show help.

EXAMPLE

    foldersynka create my-app \\
        --src ~/storage/shared/MyApp \\
        --dest ~/documents/MyApp

EOF

}

###############################################################################
# Start
###############################################################################

show_start_help() {

    cat <<EOF

foldersynka start

Start synchronization for a profile.

USAGE

    foldersynka start <profile>

EXAMPLE

    foldersynka start my-app

EOF

}

###############################################################################
# Stop
###############################################################################

show_stop_help() {

    cat <<EOF

foldersynka stop

Stop synchronization for a profile.

USAGE

    foldersynka stop <profile>

EXAMPLE

    foldersynka stop my-app

EOF

}

###############################################################################
# Restart
###############################################################################

show_restart_help() {

    cat <<EOF

foldersynka restart

Restart synchronization for a profile.

USAGE

    foldersynka restart <profile>

EXAMPLE

    foldersynka restart my-app

EOF

}

###############################################################################
# Status
###############################################################################

show_status_help() {

    cat <<EOF

foldersynka status

Display the runtime status of a profile.

USAGE

    foldersynka status <profile>

EXAMPLE

    foldersynka status my-app

EOF

}

###############################################################################
# List
###############################################################################

show_list_help() {

    cat <<EOF

foldersynka list

List all configured synchronization profiles.

USAGE

    foldersynka list

EOF

}

###############################################################################
# Remove
###############################################################################

show_remove_help() {

    cat <<EOF

foldersynka remove

Remove a synchronization profile.

USAGE

    foldersynka remove <profile>

EXAMPLE

    foldersynka remove my-app

EOF

}

###############################################################################
# Doctor
###############################################################################

show_doctor_help() {

    cat <<EOF

foldersynka doctor

Diagnose the FolderSynka installation.

USAGE

    foldersynka doctor [profile]

Checks include:

    • Termux environment
    • Required dependencies
    • Shared storage
    • Runtime state
    • Profile configuration
    • Source and destination
    • Ignore files
    • Generated services

EXAMPLES

    foldersynka doctor

    foldersynka doctor my-app

EOF

}

###############################################################################
# Ignore
###############################################################################

show_ignore_help() {

    cat <<EOF

foldersynka ignore

Manage .foldersynkaignore.

COMMANDS

    init
        Create a default ignore file.

USAGE

    foldersynka ignore my-app init

EXAMPLE

    foldersynka ignore my-app init

EOF

}

###############################################################################
# Router
###############################################################################

case "$TOPIC" in

    general)
        show_general_help
        ;;

    create)
        show_create_help
        ;;

    start)
        show_start_help
        ;;

    stop)
        show_stop_help
        ;;

    restart)
        show_restart_help
        ;;

    status)
        show_status_help
        ;;

    list)
        show_list_help
        ;;

    remove)
        show_remove_help
        ;;

    doctor)
        show_doctor_help
        ;;

    ignore)
        show_ignore_help
        ;;

    *)
        printf 'Unknown help topic: %s\n\n' "$TOPIC"
        show_general_help
        exit 1
        ;;

esac