#!/bin/sh

# Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

# Uploads a package to the servers of an environment and hands it to the deployment service of
# each one, which installs it.
#
# Nothing about any particular installation is in this repository: no host, no address, no port,
# no count of machines. Everything comes from the environment of the caller, so a CI job
# configuration or a command line decides where a package goes. This file knows how to deploy,
# not where.
#
#   SMI_DEPLOY_HOSTS         the servers, required: [user@]host[:port], several separated by
#                            spaces or commas, so one more machine is one more word
#   SMI_DEPLOY_USER          user for an entry that does not name one, default deploy
#   SMI_DEPLOY_PORT          port for an entry that does not name one, default 22
#   SMI_DEPLOY_REMOTE_DIR    where to upload, default the deploy directory of that user
#   SMI_DEPLOY_INCOMING_DIR  what the deployment service watches, default the published one
#
# The package reaches every server of the list. A server that fails does not stop the others, and
# the command ends with 1 when any of them failed.
#
# Usage: deploy.sh upload|handover|deploy PACKAGE

set -u

ACTION="${1:-}"
PACKAGE="${2:-}"
COMMAND_NAME="${0##*/}"

if [ -z "${ACTION}" ] || [ -z "${PACKAGE}" ]; then
    echo "Usage: ${COMMAND_NAME} upload|handover|deploy PACKAGE" >&2
    exit 1
fi

case "${ACTION}" in
    upload|handover|deploy)
        ;;
    *)
        echo "Usage: ${COMMAND_NAME} upload|handover|deploy PACKAGE" >&2
        exit 1
        ;;
esac

HOSTS="${SMI_DEPLOY_HOSTS:-}"
DEFAULT_USER="${SMI_DEPLOY_USER:-deploy}"
DEFAULT_PORT="${SMI_DEPLOY_PORT:-22}"
INCOMING_DIR="${SMI_DEPLOY_INCOMING_DIR:-/var/opt/setmy.info/incoming}"

if [ -z "${HOSTS}" ]; then
    echo "${COMMAND_NAME}: SMI_DEPLOY_HOSTS is not set." >&2
    echo "The servers belong to the installation, not to this repository: set them in the CI job" >&2
    echo "configuration or on the command line, for example" >&2
    echo "  SMI_DEPLOY_HOSTS='one.example.com two.example.com:2222' make deploy" >&2
    exit 1
fi

PACKAGE_NAME="${PACKAGE##*/}"
RESULT=0

# [user@]host[:port], and an IPv6 address in brackets as ssh and scp write it: [::1]:2222.
parseEntry() {
    ENTRY="${1}"
    ENTRY_USER="${DEFAULT_USER}"
    ENTRY_PORT="${DEFAULT_PORT}"

    case "${ENTRY}" in
        *@*)
            ENTRY_USER="${ENTRY%%@*}"
            ENTRY="${ENTRY#*@}"
            ;;
    esac

    case "${ENTRY}" in
        \[*\]:*)
            ENTRY_PORT="${ENTRY##*]:}"
            ENTRY_HOST="${ENTRY%%]*}"
            ENTRY_HOST="${ENTRY_HOST#[}"
            ;;
        \[*\])
            ENTRY_HOST="${ENTRY#[}"
            ENTRY_HOST="${ENTRY_HOST%]}"
            ;;
        *:*)
            ENTRY_PORT="${ENTRY##*:}"
            ENTRY_HOST="${ENTRY%%:*}"
            ;;
        *)
            ENTRY_HOST="${ENTRY}"
            ;;
    esac

    case "${ENTRY_PORT}" in
        ''|*[!0-9]*)
            echo "${COMMAND_NAME}: invalid port in '${1}'" >&2
            return 1
            ;;
    esac

    if [ -z "${ENTRY_HOST}" ]; then
        echo "${COMMAND_NAME}: no host in '${1}'" >&2
        return 1
    fi
}

uploadTo() {
    REMOTE_DIR="${SMI_DEPLOY_REMOTE_DIR:-/home/${ENTRY_USER}/deploy}"
    echo "Uploading ${PACKAGE_NAME} to ${ENTRY_USER}@${ENTRY_HOST}:${REMOTE_DIR} port ${ENTRY_PORT}"
    ssh -o BatchMode=yes -p "${ENTRY_PORT}" "${ENTRY_USER}@${ENTRY_HOST}" mkdir -p "${REMOTE_DIR}" || return 1
    # ssh takes an IPv6 address as it is, scp needs it in brackets, because its host:path form
    # would read the colons of the address as the start of the path.
    case "${ENTRY_HOST}" in
        *:*)
            SCP_HOST="[${ENTRY_HOST}]"
            ;;
        *)
            SCP_HOST="${ENTRY_HOST}"
            ;;
    esac
    scp -o BatchMode=yes -p -P "${ENTRY_PORT}" "${PACKAGE}" "${ENTRY_USER}@${SCP_HOST}:${REMOTE_DIR}/" || return 1
    ssh -o BatchMode=yes -p "${ENTRY_PORT}" "${ENTRY_USER}@${ENTRY_HOST}" ls -l "${REMOTE_DIR}" || return 1
}

# Copied in under a name the watcher does not match and renamed inside the incoming directory,
# because a rename in one directory is atomic and the service never sees a package that is still
# being written. A plain mv from the upload directory would not do: the two are usually on
# different file systems, where mv copies.
handoverTo() {
    REMOTE_DIR="${SMI_DEPLOY_REMOTE_DIR:-/home/${ENTRY_USER}/deploy}"
    echo "Handing ${PACKAGE_NAME} to the deployment service of ${ENTRY_HOST}: ${INCOMING_DIR}"
    ssh -o BatchMode=yes -p "${ENTRY_PORT}" "${ENTRY_USER}@${ENTRY_HOST}" \
        cp "${REMOTE_DIR}/${PACKAGE_NAME}" "${INCOMING_DIR}/${PACKAGE_NAME}.part" || return 1
    ssh -o BatchMode=yes -p "${ENTRY_PORT}" "${ENTRY_USER}@${ENTRY_HOST}" \
        mv "${INCOMING_DIR}/${PACKAGE_NAME}.part" "${INCOMING_DIR}/${PACKAGE_NAME}" || return 1
    echo "The deployment service of ${ENTRY_HOST} installs it; journalctl -u setmy-info-deploy.service there says how it went"
}

if [ "${ACTION}" != handover ] && [ ! -f "${PACKAGE}" ]; then
    echo "${COMMAND_NAME}: no package to deploy: ${PACKAGE}, run make package first" >&2
    exit 1
fi

for ENTRY_GIVEN in $(printf '%s' "${HOSTS}" | tr ',' ' '); do
    if ! parseEntry "${ENTRY_GIVEN}"; then
        RESULT=1
        continue
    fi

    case "${ACTION}" in
        upload)
            uploadTo || { echo "${COMMAND_NAME}: upload to ${ENTRY_HOST} failed" >&2; RESULT=1; }
            ;;
        handover)
            handoverTo || { echo "${COMMAND_NAME}: hand over on ${ENTRY_HOST} failed" >&2; RESULT=1; }
            ;;
        deploy)
            if uploadTo; then
                handoverTo || { echo "${COMMAND_NAME}: hand over on ${ENTRY_HOST} failed" >&2; RESULT=1; }
            else
                echo "${COMMAND_NAME}: upload to ${ENTRY_HOST} failed, not handing over there" >&2
                RESULT=1
            fi
            ;;
    esac
done

exit ${RESULT}
