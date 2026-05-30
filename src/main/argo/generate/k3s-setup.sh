#!/bin/sh
# K3S one-time setup for the generator Argo Workflow with host NFS.
#
# Run this once before submitting any workflows.  Safe to re-run (kubectl apply
# is idempotent).
#
# Argo Workflows must be installed before workflows can be submitted.
# Install Argo Workflows on K3S (run as root or with sudo):
#
#   ARGO_VERSION=v4.0.5
#   kubectl create namespace argo
#   kubectl apply -n argo \
#     -f https://github.com/argoproj/argo-workflows/releases/download/$ARGO_VERSION/install.yaml
#
# Install argo CLI (Linux amd64):
#   curl -sLO https://github.com/argoproj/argo-workflows/releases/download/$ARGO_VERSION/argo-linux-amd64.gz
#   gunzip argo-linux-amd64.gz
#   chmod +x argo-linux-amd64
#   sudo mv argo-linux-amd64 /usr/local/bin/argo
#   argo version
#
# Host NFS prerequisites (already done on this machine):
#   sudo dnf -y install nfs-utils
#   sudo systemctl enable --now nfs-server rpcbind
#   # /etc/exports contains:
#   #   /mnt/gintra/organizations/ee/has *(rw,sync,no_root_squash)
#   sudo exportfs -ra
#   # K3S node also needs nfs-utils for kubelet to mount NFS volumes:
#   #   (already satisfied since server and node are the same machine)

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

SCRIPT_DIR=$(dirname "$0")

# ---------------------------------------------------------------------------
# Apply manifests in order
# ---------------------------------------------------------------------------
printf "\n--- 00 namespace ---\n"
kubectl apply -f "$SCRIPT_DIR/00-generator-namespace.yaml"

printf "\n--- 01 NFS PersistentVolume ---\n"
kubectl apply -f "$SCRIPT_DIR/01-k3s-nfs-persistent-volume.yaml"

printf "\n--- 02 NFS PersistentVolumeClaim ---\n"
kubectl apply -f "$SCRIPT_DIR/02-k3s-nfs-persistent-volume-claim.yaml"

printf "\n--- 06 secrets ---\n"
kubectl apply -f "$SCRIPT_DIR/06-generator-secrets-map.yaml"

printf "\n--- 07 role ---\n"
kubectl apply -f "$SCRIPT_DIR/07-generator-role.yaml"

printf "\n--- 08 rolebinding ---\n"
kubectl apply -f "$SCRIPT_DIR/08-generator-rolebinding.yaml"

# ---------------------------------------------------------------------------
# Status
# ---------------------------------------------------------------------------
printf "\n--- PV / PVC status ---\n"
kubectl get pv generator-nfs-persistent-volume
kubectl get pvc -n generator generator-nfs-persistent-volumec

printf "\nSetup done. Submit a workflow with: sh argo-wf.sh\n"
