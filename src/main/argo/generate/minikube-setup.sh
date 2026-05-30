#!/bin/sh
# Minikube one-time setup for the generator Argo Workflow with host NFS.
#
# Run this once before submitting any workflows.  Safe to re-run (kubectl apply
# is idempotent).
#
# Argo Workflows must be installed before workflows can be submitted.
# Install Argo Workflows on Minikube:
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
# Host NFS prerequisites (shared with K3S — run once on the host):
#   sudo dnf -y install nfs-utils
#   sudo systemctl enable --now nfs-server rpcbind
#   # /etc/exports contains:
#   #   /mnt/gintra/organizations/ee/has *(rw,sync,no_root_squash)
#   sudo exportfs -ra
#
# Minikube node NFS client (run once after minikube start):
#   minikube ssh "sudo apt-get update -q && sudo apt-get install -y nfs-common"
#
# The host is reachable from Minikube at 192.168.49.1 (docker driver default).
# Verify:
#   minikube ssh "showmount -e 192.168.49.1"

set -e

SCRIPT_DIR=$(dirname "$0")

# ---------------------------------------------------------------------------
# Apply manifests in order
# ---------------------------------------------------------------------------
printf "\n--- 00 namespace ---\n"
kubectl apply -f "$SCRIPT_DIR/00-generator-namespace.yaml"

printf "\n--- 01 NFS PersistentVolume ---\n"
kubectl apply -f "$SCRIPT_DIR/01-minikube-nfs-persistent-volume.yaml"

printf "\n--- 02 NFS PersistentVolumeClaim ---\n"
kubectl apply -f "$SCRIPT_DIR/02-minikube-nfs-persistent-volume-claim.yaml"

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
kubectl get pvc -n generator generator-nfs-persistent-volume-claim

printf "\nSetup done. Submit a workflow with: argo submit -n generator --watch 09-minikube-generator-argo.yaml\n"
