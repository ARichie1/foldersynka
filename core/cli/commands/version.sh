#!/data/data/com.termux/files/usr/bin/bash

###############################################################################
# FolderSynka
# File: core/cli/commands/version.sh
#
# Description:
#   Display the installed FolderSynka version.
###############################################################################

set -euo pipefail

source "${FS_HOME}/core/lib/constants.sh"

###############################################################################
# Version
###############################################################################

VERSION_FILE="${FS_HOME}/VERSION"

if [[ -f "$VERSION_FILE" ]]; then
    FS_VERSION="$(<"$VERSION_FILE")"
else
    FS_VERSION="development"
fi

###############################################################################
# Output
###############################################################################

printf '%s v%s\n' \
    "${FS_APP_NAME}" \
    "${FS_VERSION}"