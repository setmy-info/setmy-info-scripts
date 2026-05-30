#!/bin/sh
# Pre-install Claude Code into the shared packages folder on the NFS host.
# Run once after k3s-setup.sh.  All workflow pods will use this cached binary
# and skip the ~6-minute download on every run.
#
# Usage:
#   sh setup-claude.sh            # cc=ee org=has
#   sh setup-claude.sh ee has

set -e

CC="${1:-ee}"
ORG="${2:-has}"
ORG_MOUNT="/mnt/gintra/organizations/${CC}/${ORG}"
CLAUDE_HOME="${ORG_MOUNT}/operations/packages/claude"
CLAUDE_BIN="${CLAUDE_HOME}/.local/bin/claude"

if [ -x "${CLAUDE_BIN}" ]; then
    printf "Claude already installed at: %s\n" "${CLAUDE_BIN}"
    exit 0
fi

mkdir -p "${CLAUDE_HOME}"
export HOME="${CLAUDE_HOME}"
export PATH="${CLAUDE_HOME}/.local/bin:${CLAUDE_HOME}/.claude/local/bin:${PATH}"
export SMI_CC="${CC}"
export SMI_ORG="${ORG}"
# Force musl platform — workflow pods run Alpine (musl libc).
# Without this, the installer detects the host OS (Rocky Linux/glibc) and
# downloads the glibc build which cannot run in Alpine containers.
export CLAUDE_PLATFORM="linux-x64-musl"

printf "Installing Claude Code (linux-x64-musl) to: %s\n" "${CLAUDE_HOME}"
sh "${ORG_MOUNT}/operations/packages/scripts/lib/install-claude-code.sh"
printf "Done. Cached at: %s\n" "${CLAUDE_BIN}"
