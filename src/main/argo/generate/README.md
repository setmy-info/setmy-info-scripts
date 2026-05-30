# Argo Workflows — Generator

Example Argo Workflow that creates working directories on NFS storage.
Two parallel setup tracks share common RBAC and secrets files.

## File Ordering

| #  | Generic (both)                  | Minikube                                       | K3S                                         |
|----|---------------------------------|------------------------------------------------|---------------------------------------------|
| 00 | `00-generator-namespace.yaml`   | —                                              | —                                           |
| 01 | —                               | `01-minikube-nfs-persistent-volume.yaml`       | `01-k3s-nfs-persistent-volume.yaml`         |
| 02 | —                               | `02-minikube-nfs-persistent-volume-claim.yaml` | `02-k3s-nfs-persistent-volume-claim.yaml`   |
| 05 | —                               | `05-minikube-test.yaml`                        | `05-k3s-test.yaml`                          |
| 06 | `06-generator-secrets-map.yaml` | —                                              | —                                           |
| 07 | `07-generator-role.yaml`        | —                                              | —                                           |
| 08 | `08-generator-rolebinding.yaml` | —                                              | —                                           |
| 09 | —                               | `09-minikube-generator-argo.yaml`              | `09-k3s-generator-argo.yaml`                |
| 10 | —                               | —                                              | `10-k3s-argo-serversTransport.yaml`         |
| 11 | —                               | —                                              | `11-k3s-argo-ingressroute.yaml`             |

Naming convention: `*-minikube-*` = Minikube-specific, `*-k3s-*` = K3S-specific, `*-generator-*` = shared.
Both platforms use the host machine's NFS server — no in-cluster NFS deployment.
The PVC name `generator-nfs-persistent-volume-claim` is the same on both platforms so the workflow YAML is identical.

## Scripts

| Script               | Platform        | Purpose                                              |
|----------------------|-----------------|------------------------------------------------------|
| `k3s-setup.sh`       | K3S             | One-time setup: applies PV, PVC, RBAC, secrets, ingress |
| `k3s-teardown.sh`    | K3S             | Remove all generator resources to start fresh        |
| `argo-wf.sh`         | K3S             | Submit workflow with auto-generated UUID             |
| `minikube-setup.sh`  | Minikube/Linux  | One-time setup: applies PV, PVC, RBAC, secrets      |
| `minikube-start.cmd` | Minikube/Windows| Start Minikube (docker driver)                       |
| `argo-wf.cmd`        | Minikube/Windows| Submit workflow with auto-generated UUID             |

## K3S Kubeconfig

K3S stores its kubeconfig at `/etc/rancher/k3s/k3s.yaml`, not the default `~/.kube/config`.
Both `k3s-setup.sh`, `k3s-teardown.sh`, and `argo-wf.sh` export it automatically.
To avoid setting it manually in every shell session, add to `~/.bashrc` or `~/.profile`:

```sh
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

## Quick Start (K3S)

```sh
# 0. Verify Argo Workflows is installed and running
argo submit -n argo --watch ../check/00-argo-hello-world.yaml
argo logs @latest -n argo

# 1. One-time setup (see k3s-setup.sh header for Argo Workflows install instructions)
sh k3s-setup.sh

# 2. Verify NFS mount via test pod (optional)
kubectl apply -f 05-k3s-test.yaml
kubectl exec -it nfs-persistent-volume-claim-test -n generator -- ls /mnt/gintra/organizations/ee/has
kubectl delete -f 05-k3s-test.yaml

# 3. Submit workflow
sh argo-wf.sh
```

## Teardown (K3S)

To remove all generator resources and start fresh:

```sh
sh k3s-teardown.sh
```

What it deletes, in order:

1. All workflows in the `generator` namespace
2. Test pod `nfs-persistent-volume-claim-test`
3. PersistentVolumeClaim `generator-nfs-persistent-volume-claim` (namespaced)
4. Namespace `generator` (cascade-deletes secrets, role, rolebinding)
5. PersistentVolume `generator-nfs-persistent-volume` (cluster-scoped, deleted last)

After teardown, re-run `sh k3s-setup.sh` to set everything up again.

## Quick Start (Minikube — Linux)

```sh
# 0. Start Minikube and install NFS client in the node
minikube start --driver=docker
minikube ssh "sudo apt-get update -q && sudo apt-get install -y nfs-common"

# 1. Verify host NFS export is reachable (host gateway is typically 192.168.49.1)
minikube ssh "showmount -e 192.168.49.1"

# 2. One-time setup
sh minikube-setup.sh

# 3. Verify NFS mount via test pod (optional)
kubectl apply -f 05-minikube-test.yaml
kubectl exec -it nfs-persistent-volume-claim-test -n generator -- ls /mnt/gintra/organizations/ee/has
kubectl delete -f 05-minikube-test.yaml

# 4. Submit workflow
argo submit -n generator --watch 09-minikube-generator-argo.yaml
```

## Quick Start (Minikube — Windows)

```cmd
minikube-start.cmd
minikube ssh "sudo apt-get update -q && sudo apt-get install -y nfs-common"
REM update 01-minikube-nfs-persistent-volume.yaml: set nfs.server to the Windows host IP
REM  (run: minikube ssh "ip route show default" to find it)
argo-wf.cmd
```

## Claude API Token

### Getting the token

1. Go to **https://console.anthropic.com/**
2. Sign up or log in
3. Navigate to **API Keys** (left sidebar)
4. Click **Create Key**, give it a name, copy the value — it starts with `sk-ant-`
5. Store it somewhere safe; it is shown only once

### Storing the token in Kubernetes

The secret `generator-secrets` in `06-generator-secrets-map.yaml` holds the token
under the key `claude-token`.  The file ships with a placeholder (`dummy-token`).

Update it with your real key (do **not** commit the real key to git):

```sh
# Apply directly without touching the file
kubectl create secret generic generator-secrets \
    --namespace generator \
    --from-literal=claude-token=sk-ant-YOUR-KEY-HERE \
    --dry-run=client -o yaml | kubectl apply -f -

# Verify (shows base64-encoded value)
kubectl get secret generator-secrets -n generator -o yaml
```

Or encode manually and edit the YAML:

```sh
echo -n "sk-ant-YOUR-KEY-HERE" | base64
# paste result into 06-generator-secrets-map.yaml under claude-token:
```

### Using the token in a workflow container

The Claude CLI reads the key from the `ANTHROPIC_API_KEY` environment variable.
Inject it from the secret in any workflow container template:

```yaml
container:
    image: ghcr.io/anthropics/claude-code:latest   # or any image with claude CLI
    env:
        -   name: ANTHROPIC_API_KEY
            valueFrom:
                secretKeyRef:
                    name: generator-secrets
                    key: anthropic-api-key
    command: [ sh, -c ]
    args:
        - |
            claude --print "Your prompt here"
```

`--print` (short: `-p`) runs Claude non-interactively and exits — required for
automated workflow steps where there is no terminal.

## NFS Directory Structure (host — shared by K3S and Minikube)

The K3S node exports `/mnt/gintra/organizations/ee/has` via NFS.
Inside the workflow pod that path is mounted at the same path.

```
/mnt/gintra/organizations/ee/has/
├── development/
│   └── configuration/
└── operations/
    ├── ai/           ← AI working directories created per UUID
    ├── packages/
    └── workflows/    ← Workflow working directories created per UUID
```
