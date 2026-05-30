#!/bin/sh
# Submit the K3S Argo Workflow with a freshly generated UUID.
# PROMPT.md, optional attachments and Claude config are copied to the NFS AI
# working directory before submission so every workflow step finds them in place.
#
# Prerequisites:
#   sh k3s-setup.sh     (run once to create namespace, PV, PVC, RBAC)
#   argo CLI in PATH    (see k3s-setup.sh header for install instructions)
#
# Usage:
#   sh argo-wf.sh [cc [org [prompt_file [model [file1 file2 ...]]]]]
#
# Examples:
#   sh argo-wf.sh
#   sh argo-wf.sh ee has
#   sh argo-wf.sh ee has PROMPT.md claude-opus-4-8
#   sh argo-wf.sh ee has PROMPT.md claude-sonnet-4-6 design.pdf mockup.png
#
# Supported models: claude-opus-4-8  claude-sonnet-4-6  claude-haiku-4-5

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

CC="${1:-ee}"
ORG="${2:-has}"
PROMPT_FILE="${3:-PROMPT.md}"
MODEL="${4:-claude-sonnet-4-6}"
shift 4 2>/dev/null || shift $# 2>/dev/null || true
FILES="$*"

if [ ! -f "$PROMPT_FILE" ]; then
    printf "PROMPT.md not found: %s\n" "$PROMPT_FILE" >&2
    exit 1
fi

UUID=$(uuid)

NFS_ORG="/mnt/gintra/organizations/${CC}/${ORG}"
AI_WORKDIR="${NFS_ORG}/operations/ai/${UUID}"

mkdir -p "${AI_WORKDIR}/.claude"
cp "$PROMPT_FILE" "${AI_WORKDIR}/PROMPT.md"
printf "Prompt  : %s/PROMPT.md\n" "$AI_WORKDIR"

# Copy optional attachment files into the AI workdir.
FILES_PARAM=""
for f in ${FILES}; do
    if [ ! -f "$f" ]; then
        printf "File not found: %s\n" "$f" >&2
        exit 1
    fi
    cp "$f" "${AI_WORKDIR}/"
    fname=$(basename "$f")
    FILES_PARAM="${FILES_PARAM:+${FILES_PARAM} }${fname}"
    printf "Attached: %s/%s\n" "$AI_WORKDIR" "$fname"
done

# Copy local Claude CLI configuration (credentials, settings, plugins) so the
# workflow node uses the same auth session as the local CLI.
CLAUDE_SRC="${HOME}/.claude"
CLAUDE_DST="${AI_WORKDIR}/.claude"
if [ -d "${CLAUDE_SRC}" ]; then
    for f in .credentials.json settings.json mcp-needs-auth-cache.json; do
        if [ -f "${CLAUDE_SRC}/${f}" ]; then
            cp "${CLAUDE_SRC}/${f}" "${CLAUDE_DST}/${f}"
        fi
    done
    if [ -d "${CLAUDE_SRC}/plugins" ]; then
        cp -r "${CLAUDE_SRC}/plugins" "${CLAUDE_DST}/"
    fi
    printf "Claude config copied from: %s\n" "${CLAUDE_SRC}"
else
    printf "Warning: %s not found — set ANTHROPIC_API_KEY in the secret\n" "${CLAUDE_SRC}"
fi

SCRIPT_DIR=$(dirname "$0")

printf "Submitting: cc=%s org=%s model=%s uuid=%s\n" "$CC" "$ORG" "$MODEL" "$UUID"

argo submit -n generator --watch \
    -p cc="$CC" \
    -p org="$ORG" \
    -p uuid="$UUID" \
    -p model="$MODEL" \
    -p files="$FILES_PARAM" \
    "$SCRIPT_DIR/09-k3s-generator-argo.yaml"

printf "\nDone. UUID: %s\n" "$UUID"
