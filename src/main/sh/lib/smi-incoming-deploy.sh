#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

# Generic nginx deployment plugin for smi-incoming-deploy.
#
# It is never called by its own name: every symbolic link in /opt/setmy.info/lib/incoming points
# here, and the link name selects the packages. A link named angular-start-project.sh handles each
# incoming .tar.gz whose file name contains angular-start-project; every other package is left to
# the other links. One more deployment is one more link.
#
# smi-incoming-deploy gives every package to every plugin, so a plugin decides for itself whether
# a package is one of its own and ends with 0 when it is not. The package file belongs to
# smi-incoming-deploy: it removes it once every plugin has handled it, and moves it to
# /var/opt/setmy.info/failed when a plugin ends with an error.
#
# The stage is the second argument, published or draft, which is the directory the external
# system dropped the package into. It decides which of the two directories of the application is
# written, the published one or the draft one:
#
#   published  /usr/share/nginx/vhosts/setmy.info.gintra/apps/old
#   draft      /usr/share/nginx/vhosts/setmy.info.gintra/draft/apps/old
#
# nginx serves vhosts/$server_name/$vhost_variant, where the variant is empty or draft/, so a
# draft is checked by whoever may see drafts and the external system publishes it by sending the
# same package to the published incoming directory.
#
# The host and the application of this deployment:

VHOST="setmy.info.gintra"
APP="old"
VHOSTS_DIR="/usr/share/nginx/vhosts"

INPUT_FILE="$1"
STAGE="${2:-published}"

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
    echo "Error: Pattern '$PATTERN' matched, but '$INPUT_FILE' is not a file" >&2
    exit 1
fi

case "$STAGE" in
    draft)
        VARIANT="draft/"
        ;;
    published)
        VARIANT=""
        ;;
    *)
        echo "Error: unknown stage '$STAGE' for '$FILE_NAME'" >&2
        exit 1
        ;;
esac

TARGET_DIR="${VHOSTS_DIR}/${VHOST}/${VARIANT}apps/${APP}"

if [ ! -d "${VHOSTS_DIR}/${VHOST}" ]; then
    echo "Error: no virtual host directory ${VHOSTS_DIR}/${VHOST} for '$FILE_NAME'" >&2
    exit 1
fi

# An archive whose files are under one top directory is unpacked without it, so an Angular build
# of dist/old/index.html becomes apps/old/index.html.
STRIP_COMPONENTS=0
if [ "$(tar tzf "$INPUT_FILE" | cut -d/ -f1 | sort -u | grep -c .)" = 1 ]; then
    case "$(tar tzf "$INPUT_FILE" | head -1)" in
        */*)
            STRIP_COMPONENTS=1
            ;;
    esac
fi

# Unpacked beside the target and moved into place with one mv, so a request is served either the
# previous deployment or this one, never a half unpacked directory.
STAGING_DIR="${TARGET_DIR}.incoming.$$"
PREVIOUS_DIR="${TARGET_DIR}.previous.$$"

rm -rf "${STAGING_DIR}"
if ! mkdir -p "${STAGING_DIR}"; then
    echo "Error: could not create ${STAGING_DIR}" >&2
    exit 1
fi

if ! tar xvzf "$INPUT_FILE" -C "${STAGING_DIR}" --strip-components="${STRIP_COMPONENTS}"; then
    echo "Error: Unpacking '$INPUT_FILE' to '${TARGET_DIR}' failed" >&2
    rm -rf "${STAGING_DIR}"
    exit 1
fi

chown -R root:root "${STAGING_DIR}"
find "${STAGING_DIR}" -type d -exec chmod 0755 {} +
find "${STAGING_DIR}" -type f -exec chmod 0644 {} +

if [ -d "${TARGET_DIR}" ] && ! mv "${TARGET_DIR}" "${PREVIOUS_DIR}"; then
    echo "Error: could not move the current '${TARGET_DIR}' aside" >&2
    rm -rf "${STAGING_DIR}"
    exit 1
fi

if ! mv "${STAGING_DIR}" "${TARGET_DIR}"; then
    echo "Error: could not move '${STAGING_DIR}' to '${TARGET_DIR}'" >&2
    [ -d "${PREVIOUS_DIR}" ] && mv "${PREVIOUS_DIR}" "${TARGET_DIR}"
    rm -rf "${STAGING_DIR}"
    exit 1
fi

rm -rf "${PREVIOUS_DIR}"

# The SELinux type decides whether nginx may read the files at all, and it is inherited from the
# directory the files were created in, so it is set after the move.
if command -v restorecon > /dev/null 2>&1; then
    restorecon -R "${TARGET_DIR}" || echo "Warning: restorecon of '${TARGET_DIR}' failed" >&2
fi

echo "Success: Unpacked '$INPUT_FILE' as ${STAGE} to '${TARGET_DIR}'"

exit 0
