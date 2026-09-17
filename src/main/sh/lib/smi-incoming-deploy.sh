#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

# Generic nginx deployment plugin for smi-incoming-deploy.
#
# It is never called by its own name: every symbolic link in /opt/setmy.info/lib/incoming points
# here, and the link name selects the packages. A link named angular-start-project.sh handles each
# incoming .tar.gz whose file name contains angular-start-project and unpacks it into the nginx
# directory; every other package is left to the other links. One more deployment is one more link.

INPUT_FILE="$1"
TARGET_DIR="/usr/share/nginx"

SCRIPT_NAME="${0##*/}"
PATTERN="${SCRIPT_NAME%.sh}"
# Only the file name is compared, so a directory name in the path never selects a package.
FILE_NAME="${INPUT_FILE##*/}"

if [ -z "$INPUT_FILE" ]; then
    exit 0
fi

case "$FILE_NAME" in
    *"$PATTERN"*)
        ;;
    *)
        exit 0
        ;;
esac

if [ ! -f "$INPUT_FILE" ]; then
    echo "Warning: Pattern '$PATTERN' matched, but file '$INPUT_FILE' was not found!" >&2
    exit 0
fi

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

if ! tar xvzf "$INPUT_FILE" -C "$TARGET_DIR"; then
    echo "Error: Unpacking '$INPUT_FILE' to '$TARGET_DIR' failed" >&2
    exit 1
fi
echo "Success: Unpacked '$INPUT_FILE' to '$TARGET_DIR'"

exit 0
