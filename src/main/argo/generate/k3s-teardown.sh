#!/bin/sh
# K3S teardown: removes all generator resources so setup can be started fresh.
#
# Order matters:
#   1. Workflows and pods first (consumers of PVC)
#   2. PVC second (bound to PV)
#   3. Namespace third (deletes remaining namespaced resources)
#   4. PV last (cluster-scoped, must be deleted explicitly)
#
# Usage:
#   sh k3s-teardown.sh

set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

printf "--- Delete all workflows in generator namespace ---\n"
kubectl delete workflows --all -n generator --ignore-not-found

printf "\n--- Delete test pod if running ---\n"
kubectl delete pod nfs-persistent-volume-claim-test -n generator --ignore-not-found

printf "\n--- Delete PersistentVolumeClaim ---\n"
kubectl delete pvc generator-nfs-persistent-volume-claim -n generator --ignore-not-found

printf "\n--- Delete namespace (removes secrets, role, rolebinding, remaining pods) ---\n"
kubectl delete namespace generator --ignore-not-found

printf "\n--- Delete PersistentVolume (cluster-scoped) ---\n"
kubectl delete pv generator-nfs-persistent-volume --ignore-not-found

printf "\nTeardown done. Run sh k3s-setup.sh to set up again.\n"
