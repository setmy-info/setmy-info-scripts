#!/bin/sh
# Submit the K3S Argo Workflow with a freshly generated UUID.
#
# Prerequisites:
#   sh k3s-setup.sh     (run once to create namespace, PV, PVC, RBAC)
#   argo CLI in PATH    (see k3s-setup.sh header for install instructions)
#
# Usage:
#   sh argo-wf.sh
#   sh argo-wf.sh ee has          # override cc and org

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

CC="${1:-ee}"
ORG="${2:-has}"

# Generate UUID: prefer uuidgen, fall back to kernel random, then od
UUID=$(uuid)

SCRIPT_DIR=$(dirname "$0")

printf "Submitting workflow: cc=%s org=%s uuid=%s\n" "$CC" "$ORG" "$UUID"

argo submit -n generator --watch \
    -p cc="$CC" \
    -p org="$ORG" \
    -p uuid="$UUID" \
    "$SCRIPT_DIR/09-k3s-generator-argo.yaml"

printf "\nDone. UUID: %s\n" "$UUID"
