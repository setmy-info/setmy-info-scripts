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

echo "--- Delete all workflows in generator namespace ---"
kubectl delete workflows --all -n generator --ignore-not-found

echo "\n--- Delete test pod if running ---"
kubectl delete pod nfs-persistent-volume-claim-test -n generator --ignore-not-found

echo "\n--- Delete PersistentVolumeClaim ---"
kubectl delete pvc generator-nfs-persistent-volume-claim -n generator --ignore-not-found

echo "\n--- Delete namespace (removes secrets, role, rolebinding, remaining pods) ---"
kubectl delete namespace generator --ignore-not-found

echo "\n--- Delete PersistentVolume (cluster-scoped) ---"
kubectl delete pv generator-nfs-persistent-volume --ignore-not-found

echo "\n--- Delete argo IngressRoute (11) ---"
kubectl delete ingressroute argo-server -n argo --ignore-not-found

echo "\n--- Delete argo ServersTransport (10) ---"
kubectl delete serverstransport argo-insecure -n argo --ignore-not-found

echo "\nTeardown done. Run sh k3s-setup.sh to set up again."
