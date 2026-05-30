# Argo Workflows — Generator

Example Argo Workflow that creates working directories on NFS storage.
Two parallel setup tracks share common RBAC and secrets files.

## File Ordering

| #  | Minikube                                  | K3S                                              |
|----|-------------------------------------------|--------------------------------------------------|
| 00 | `00-generator-namespace.yaml`             | `00-generator-namespace.yaml`                    |
| 01 | —                                         | `01-k3s-nfs-persistent-volume.yaml`              |
| 02 | —                                         | `02-k3s-nfs-persistent-volume-claim.yaml`        |
| 03 | `03-generator-nfs-server-deployment.yaml` | —                                                |
| 04 | `04-generator-nfs-server-service.yaml`    | —                                                |
| 05 | `05-generator-test.yaml`                  | `05-k3s-test.yaml`                               |
| 06 | `06-generator-secrets-map.yaml`           | `06-generator-secrets-map.yaml`                  |
| 07 | `07-generator-role.yaml`                  | `07-generator-role.yaml`                         |
| 08 | `08-generator-rolebinding.yaml`           | `08-generator-rolebinding.yaml`                  |
| 09 | `09-generator-argo.yaml`                  | `09-k3s-generator-argo.yaml`                     |

Files named `*-generator-*` are Minikube-specific. Files named `*-k3s-*` are K3S-specific.
Shared files (06–08) carry the `generator` prefix and apply to both tracks.
PersistentVolume/PersistentVolumeClaim (01–02) always precede Deployment/Service (03–04).

## Scripts

| Script              | Platform | Purpose                                                              |
|---------------------|----------|----------------------------------------------------------------------|
| `k3s-setup.sh`      | K3S      | One-time setup: applies PV, PVC, RBAC, secrets                      |
| `k3s-teardown.sh`   | K3S      | Remove all generator resources to start fresh                        |
| `argo-wf.sh`        | K3S      | Submit workflow with auto-generated UUID                             |
| `minikube-start.cmd`| Minikube | Start Minikube with host folder mount                                |
| `argo-wf.cmd`       | Minikube | Submit workflow with auto-generated UUID                             |

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
argo submit -n argo --watch 00-k3s-argo-hello-world.yaml
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

## Quick Start (Minikube)

```cmd
minikube-start.cmd
kubectl apply -f 00-generator-namespace.yaml
kubectl apply -f 03-generator-nfs-server-deployment.yaml
kubectl apply -f 04-generator-nfs-server-service.yaml
kubectl apply -f 06-generator-secrets-map.yaml
kubectl apply -f 07-generator-role.yaml
kubectl apply -f 08-generator-rolebinding.yaml
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

## NFS Directory Structure (K3S host)

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
