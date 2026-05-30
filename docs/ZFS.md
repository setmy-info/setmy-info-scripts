# ZFS Setup, Gintra, and NFS Export Overview

## ZFS Pool: tank

### Physical Layout

| Property      | Value                  |
|---------------|------------------------|
| Pool name     | `tank`                 |
| Topology      | mirror-0 (RAID-1)      |
| Disk 1        | `<disk1>`              |
| Disk 2        | `<disk2>`              |
| Total size    | `<total>`              |
| Allocated     | `<allocated>`          |
| Free          | `<free>`               |
| Capacity      | `<cap> %`              |
| Fragmentation | 0 %                    |
| Dedup ratio   | 1.00x (dedup disabled) |
| Health        | ONLINE, no errors      |

Last resilver completed successfully with 0 errors.

### Pool Feature Warning

```
status: Some supported and requested features are not enabled on the pool.
action: Enable all features using 'zpool upgrade'.
```

The pool works fine but some newer ZFS features are inactive. After running
`zpool upgrade tank` the pool will no longer be readable by older ZFS
implementations that do not support those features.

To upgrade:

```bash
sudo zpool upgrade tank
zpool status tank   # confirm no warnings remain
```

---

## ZFS Datasets

The root dataset `tank` is mounted at `/mnt/gintra`. Child datasets inherit that
mount point and extend the path with their dataset name.

| Dataset                         | Mount point                            | Notes             |
|---------------------------------|----------------------------------------|-------------------|
| `tank`                          | `/mnt/gintra`                          | pool root         |
| `tank/organizations`            | `/mnt/gintra/organizations`            | structural        |
| `tank/organizations/<cc>`       | `/mnt/gintra/organizations/<cc>`       | structural        |
| `tank/organizations/<cc>/<org>` | `/mnt/gintra/organizations/<cc>/<org>` | holds actual data |
| `tank/organizations/<cc>/<org>/operations/packages` | `/mnt/gintra/organizations/<cc>/<org>/operations/packages` | per-org pkg cache (optional sub-dataset) |

All datasets share the same pool quota so AVAIL is the same for every level.
Only the leaf dataset `tank/organizations/<cc>/<org>` holds actual data; the
three ancestor datasets are structural containers.

Concrete example (current installation):

| Dataset                     | Mount point                        |
|-----------------------------|------------------------------------|
| `tank/organizations/ee`     | `/mnt/gintra/organizations/ee`     |
| `tank/organizations/ee/has` | `/mnt/gintra/organizations/ee/has` |

Dataset properties (from `mount` output):

```
rw, relatime, seclabel, xattr, noacl, casesensitive
```

### Dataset Hierarchy Purpose

The hierarchy encodes a three-level namespace:

```
tank
└── organizations          # top-level grouping for all organisations
    └── <cc>               # ISO 3166-1 alpha-2 country code
        └── <org>          # organisation short name
            ├── development/
            │   └── configuration/
            │       └── pki/
            └── operations/
                ├── ai/
                ├── packages/
                └── workflows/
```

Within each org dataset the directory layout separates long-lived configuration
(`development/`) from runtime workloads (`operations/`). This is a plain
directory convention inside a single ZFS dataset, not separate child datasets
(unless explicitly created as such).

This mirrors the path convention used by `smi-organization-location`:

```
$(smi-organizations-location)/<COUNTRY_CODE>/<ORG_SHORT_NAME>
```

---

## Path Concepts: Two Gintra Paths

The scripts distinguish two separate root paths for gintra data.

### 1. Logical / application path — `smi-gintra-location`

```
/var/opt/setmy.info/gintra
```

Returned by `smi-gintra-location`. This is the **software-facing** root that all
`smi-*` helper scripts use when building sub-paths (organizations, persons, …).

The path is intentionally designed to follow the
**Linux Filesystem Hierarchy Standard (FHS)**. The FHS mandates that add-on
software installed under `/opt/<provider>` must store its variable runtime data
under `/var/opt/<provider>`. Since the setmy.info toolchain installs to
`/opt/setmy.info`, its variable data belongs in `/var/opt/setmy.info`. The
`gintra` subdirectory is the designated root for all gintra-related data folders
within that hierarchy (organizations, persons, and other structured data
managed by the `smi-*` scripts).

On Linux: derived from `smi-var-location` → `/var/opt/setmy.info` + `/gintra`.
On FreeBSD: derived from `$(smi-location)/var/setmy.info` + `/gintra`.

### 2. Physical / ZFS mount path — `smi-gintra-mount-location`

```
/mnt/gintra
```

Returned by `smi-gintra-mount-location`. This is the **mount point** where
the ZFS pool `tank` is actually attached to the filesystem tree.

### Relationship between the two

The two paths are bridged by a symlink created at system setup time:

```
lrwxrwxrwx. 1 root root 11  /var/opt/setmy.info/gintra -> /mnt/gintra
```

So every `smi-*` script that resolves a path through `smi-gintra-location`
(e.g. `/var/opt/setmy.info/gintra/organizations/<cc>/<org>`) is transparently
redirected to the ZFS dataset mounted at `/mnt/gintra/organizations/<cc>/<org>`.
This keeps the FHS-compliant logical path stable for scripts and tooling while
the physical storage can be on any ZFS pool, mount point, or replaced storage
without changing any script.

---

## `smi-*` Location Scripts — Full Reference

All scripts installed to `/opt/setmy.info/bin/`.

### Foundation

| Script               | Output (Linux)                                                             | Notes                                                 |
|----------------------|----------------------------------------------------------------------------|-------------------------------------------------------|
| `smi-location`       | `/opt/setmy.info`                                                          | Base installation root                                |
| `smi-bin-location`   | `/opt/setmy.info/bin`                                                      |                                                       |
| `smi-lib-location`   | `/opt/setmy.info/lib`                                                      |                                                       |
| `smi-etc-location`   | `/opt/setmy.info/etc` (Linux) / `$(smi-location)/etc/setmy.info` (FreeBSD) |                                                       |
| `smi-man-location`   | `/opt/setmy.info/man`                                                      |                                                       |
| `smi-var-location`   | `/var/opt/setmy.info`                                                      | Linux only; FreeBSD: `$(smi-location)/var/setmy.info` |
| `smi-temp-location`  | `/tmp/setmy.info`                                                          |                                                       |
| `smi-provider`       | `setmy.info`                                                               | Read from `base.sh` `$PROVIDER` variable              |
| `smi-include <file>` | `/opt/setmy.info/lib/<file>`                                               | Returns path for `. $(smi-include foo.sh)`            |

### Home / user

| Script                       | Output                                                |
|------------------------------|-------------------------------------------------------|
| `smi-home-location`          | `$HOME/.setmy.info` (overridable via `$SMI_HOME_DIR`) |
| `smi-home-packages-location` | `$HOME/.setmy.info/packages`                          |

### Gintra (data store)

| Script                       | Output                                     |
|------------------------------|--------------------------------------------|
| `smi-gintra-location`        | `/var/opt/setmy.info/gintra`               |
| `smi-gintra-mount-location`  | `/mnt/gintra`                              |
| `smi-organizations-location` | `/var/opt/setmy.info/gintra/organizations` |
| `smi-persons-location`       | `/var/opt/setmy.info/gintra/persons`       |

### Organisation paths (parameterised)

```sh
smi-organization-location <COUNTRY_CODE> <ORG_SHORT_NAME>
# → /var/opt/setmy.info/gintra/organizations/<COUNTRY_CODE>/<ORG_SHORT_NAME>
# Example: smi-organization-location <cc> <org>
#        → /var/opt/setmy.info/gintra/organizations/<cc>/<org>

smi-organization-dir-location <COUNTRY_CODE> <ORG_SHORT_NAME> <DIR>
# → $(smi-organization-location <COUNTRY_CODE> <ORG_SHORT_NAME>)/<DIR>
# Example: smi-organization-dir-location <cc> <org> development
#        → /var/opt/setmy.info/gintra/organizations/<cc>/<org>/development
```

COUNTRY_CODE follows ISO 3166-1 alpha-2.

### Person paths (hashed)

```sh
smi-person-name-hash <FIRST_NAME> <LAST_NAME>
# → person_hash_<26-char SHA-512 prefix>
# Uses fixed UUID salt
# Example: smi-person-name-hash John Doe
#        → person_hash_<26-char-hash>

smi-person-location <FIRST_NAME> <LAST_NAME>
# → /var/opt/setmy.info/gintra/persons/person_hash_<26-char-hash>
```

### Content / software locations

| Script                  | Output                         |
|-------------------------|--------------------------------|
| `smi-profiles-location` | `/opt/setmy.info/lib/profiles` |
| `smi-packages-location` | `/opt/setmy.info/lib/packages` |

### Deprecated location scripts

These exist for backward compatibility and output a warning comment in their
source. Do not use in new scripts.

| Script                   | Deprecated path                          |
|--------------------------|------------------------------------------|
| `smi-localhost-location` | `/opt/setmy.info/etc/localhost`          |
| `smi-config`             | `/opt/setmy.info/etc/localhost/config`   |
| `smi-net-location`       | `/var/opt/setmy.info/net`                |
| `smi-nics-location`      | `/opt/setmy.info/etc/localhost/nics`     |
| `smi-nodes-location`     | `/opt/setmy.info/etc/localhost/nodes`    |
| `smi-services-location`  | `/opt/setmy.info/etc/localhost/services` |

---

## NFS Export

### `/etc/exports`

```
/mnt/gintra/organizations/<cc>/<org> *(rw,sync,no_root_squash)
#/var/opt/setmy.info/diskless/chroot *(rw,sync,no_root_squash)
#/var/opt/setmy.info/diskless/home *(rw,sync,no_root_squash)
#/var/opt/setmy.info/diskless/var *(rw,sync,no_root_squash)
```

The `operations/packages` directory lives inside the org dataset and is
automatically covered by the org export. No separate export entry is needed.
The export uses `rw` so a dedicated Argo download step can write packages
into the cache; install pods use `readOnly: true` in their volumeMount.

The export path uses the actual ZFS filesystem mount path, not the ZFS dataset
name. NFS requires real filesystem paths — dataset names (e.g. `tank/…`) are
not valid export paths.

After any change to `/etc/exports`:

```bash
sudo exportfs -ra          # reload exports without restarting nfsd
exportfs -v                # verify active exports
showmount -e localhost     # confirm share is visible to clients
```

To test a mount from a client:

```bash
sudo mount -t nfs <nfs-server-hostname>:/mnt/gintra/organizations/<cc>/<org> /mnt/test
```

### NFS Service Commands (Rocky/Fedora)

```bash
sudo systemctl enable --now nfs-server
sudo systemctl status nfs-server
sudo firewall-cmd --add-service=nfs --permanent
sudo firewall-cmd --add-service=rpc-bind --permanent
sudo firewall-cmd --add-service=mountd --permanent
sudo firewall-cmd --reload
```

---

## ZFS Pool Maintenance

### Check status

```bash
zpool status tank
zpool list tank
zfs list
```

### Scrub (data integrity check)

```bash
sudo zpool scrub tank
zpool status tank   # watch progress
```

Run a scrub at least monthly. The pool also records each resilver.

### Upgrade pool features

```bash
sudo zpool upgrade tank
zpool status tank   # warning should be gone
```

### Snapshot management

```bash
# Create snapshot
sudo zfs snapshot tank/organizations/<cc>/<org>@$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot

# Rollback (destructive — destroys data written after the snapshot)
sudo zfs rollback tank/organizations/<cc>/<org>@<YYYYMMDD>

# Destroy a snapshot
sudo zfs destroy tank/organizations/<cc>/<org>@<YYYYMMDD>
```

### Add a dataset

```bash
sudo zfs create tank/organizations/<cc>/<new-org>
zfs list
```

New datasets inherit the parent's properties (mount point, compression, etc.)
unless overridden.

### Check free space

```bash
zpool list tank          # pool-level free
zfs list -o name,used,avail,refer,mountpoint
```

---

## PKI Integration with Gintra / Tank

`pki.sh` (lib) and `smi-pki-ca-create` / `smi-pki-create-domain-cert`
store certificate material inside the organisation's dataset under a
conventional sub-path:

```
/mnt/gintra/organizations/<cc>/<org>/development/configuration/pki/
```

Usage:

```bash
# Create CA for organisation domain
smi-pki-ca-create \
    /mnt/gintra/organizations/<cc>/<org>/development/configuration/pki \
    <org>.<cc>.gintra

# Sign a domain certificate
smi-pki-create-domain-cert \
    /mnt/gintra/organizations/<cc>/<org>/development/configuration/pki \
    <service>.<org>.<cc>.gintra
```

Where `<cc>` is the ISO 3166-1 alpha-2 country code and `<org>` is the
organisation short name.

---

## Diskless Boot NFS (Reference)

`diskless.sh` (lib) sets up PXE / NFS diskless clients. Related exports that
are currently commented out in `/etc/exports`:

```
#/var/opt/setmy.info/diskless/chroot *(rw,sync,no_root_squash)
#/var/opt/setmy.info/diskless/home *(rw,sync,no_root_squash)
#/var/opt/setmy.info/diskless/var *(rw,sync,no_root_squash)
```

These use the legacy `/var/opt/setmy.info` tree, not the ZFS pool, and are
independent of the `tank` setup.

---

## Kubernetes / K3S Integration

### Goal

The `smi-*` scripts must work identically inside containers as on the host.
The only requirement is that `/mnt/gintra` inside the container resolves to
real ZFS data. The symlink `/var/opt/setmy.info/gintra -> /mnt/gintra` is
baked into the base Docker image; the actual data arrives via a mounted volume.

### Base Image Setup

The base image must create the mount point and the FHS symlink at build time:

```dockerfile
RUN mkdir -p /mnt/gintra \
 && mkdir -p /var/opt/setmy.info \
 && ln -s /mnt/gintra /var/opt/setmy.info/gintra
```

With this in place, every `smi-*` script resolves paths exactly as it does on
the host. No script changes are needed.

### Storage Options

Three practical approaches, from simplest to most scalable:

#### Option A — hostPath (single-node K3S, simplest)

Mount the host directory directly into the pod. No PV/PVC objects needed for
quick setups, but the pod is pinned to the node that has the ZFS pool.

```yaml
volumes:
  - name: gintra
    hostPath:
      path: /mnt/gintra
      type: Directory
```

Use `nodeSelector` or `nodeAffinity` to ensure the pod lands on the ZFS host:

```yaml
nodeSelector:
  kubernetes.io/hostname: <zfs-node-name>
```

#### Option B — Local PersistentVolume with node affinity (recommended for single-node)

More idiomatic Kubernetes than bare hostPath. The PV explicitly declares which
node it lives on; the scheduler enforces it automatically.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gintra-pv
spec:
  capacity:
    storage: 800Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/gintra
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <zfs-node-name>
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gintra-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  resources:
    requests:
      storage: 800Gi
```

#### Option C — NFS PersistentVolume (multi-node, ReadWriteMany)

The host already exports `/mnt/gintra` via NFS (see NFS Export section).
Any node in the cluster can mount it; multiple pods can read/write
simultaneously.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gintra-nfs-pv
spec:
  capacity:
    storage: 800Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: <nfs-server-ip>
    path: /mnt/gintra
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gintra-nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 800Gi
```

NFS requires `nfs-utils` on every K3S worker node:

```bash
sudo dnf install -y nfs-utils
```

### Mounting in a Pod / Deployment

Regardless of which option is used, the volume is always mounted at
`/mnt/gintra` inside the container:

```yaml
spec:
  containers:
    - name: app
      image: <image>
      volumeMounts:
        - name: gintra
          mountPath: /mnt/gintra
  volumes:
    - name: gintra
      persistentVolumeClaim:
        claimName: gintra-pvc   # or gintra-nfs-pvc
```

### Per-Organisation Datasets as Separate PVs

Instead of mounting the entire gintra tree, each organisation dataset can be
exposed as its own PV and mounted only into the containers that belong to that
organisation:

```
tank/organizations/<cc>/<org>  →  PV gintra-<cc>-<org>-pv
                               →  PVC gintra-<cc>-<org>-pvc
                               →  mountPath: /mnt/gintra/organizations/<cc>/<org>
```

This limits blast radius — a container only sees its own organisation data, not
the full tree. The smi-* scripts still work because they build paths through
`smi-organization-location <cc> <org>`, which resolves to exactly that subtree.

### Choosing Between Options

| Scenario                            | Recommended option        |
|-------------------------------------|---------------------------|
| Single-node K3S, quick setup        | A — hostPath              |
| Single-node K3S, production-like    | B — Local PV              |
| Multi-node cluster                  | C — NFS PV                |
| Fine-grained per-org access control | Per-org PVs (any option)  |
| Dynamic ZFS dataset provisioning    | democratic-csi ZFS driver |

`democratic-csi` is a CSI driver that talks directly to ZFS over SSH or HTTP
and can provision/snapshot datasets on demand as PVs. It is the most native
integration but requires additional setup beyond the scope of this document.

---

## Argo Workflows Multi-Tenant Storage — Plan

Status: **DRAFT / PLANNING**

### Overview

Each organisation has its own ZFS dataset. Argo Workflows receives country code
(`cc`) and org short name (`org`) as workflow parameters and uses them to
construct PVC names and mount paths. Pods see only their own organisation's
data. For workflow-level isolation, a UUID-based subdirectory is created inside
the org dataset and mounted as the pod's private workspace — parallel workflow
runs cannot access each other's working directories.

### ZFS Dataset Structure (planned)

```
tank/organizations/<cc>/<org>                        # org root dataset
tank/organizations/<cc>/<org>/operations/ai          # AI sub-dataset (optional)
```

Directory layout inside each org dataset (plain directories unless noted):

```
<org-root>/
├── development/
│   └── configuration/
│       └── pki/                                     # CA and domain certs
└── operations/
    ├── ai/
    │   └── <workflow-uuid>/                         # AI workflow workspace
    └── workflows/
        └── <workflow-uuid>/                         # general workflow workspace
```

The `operations/` subtree holds all runtime workload data. UUID directories
under `operations/workflows/` and `operations/ai/` are created at workflow
start by an init container and destroyed (or archived) at workflow end.

Concrete example (`ee/has`):

```
/mnt/gintra/organizations/ee/has/
├── development/configuration/pki/
└── operations/
    ├── ai/
    └── workflows/
```

### PV / PVC Naming Convention

| Object   | Name pattern               | Example                    |
|----------|----------------------------|----------------------------|
| PV       | `gintra-pv-<cc>-<org>`     | `gintra-pv-<cc>-<org>`     |
| PVC      | `gintra-pvc-<cc>-<org>`    | `gintra-pvc-<cc>-<org>`    |
| PV (AI)  | `gintra-pv-<cc>-<org>-ai`  | `gintra-pv-<cc>-<org>-ai`  |
| PVC (AI) | `gintra-pvc-<cc>-<org>-ai` | `gintra-pvc-<cc>-<org>-ai` |

PVC names are constructed at template level using Argo parameter substitution:

```
gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}
```

### PV / PVC Manifests

#### Per-org PV (local, single-node K3S)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gintra-pv-<cc>-<org>
  labels:
    gintra-cc: <cc>
    gintra-org: <org>
spec:
  capacity:
    storage: 100Gi          # adjust per org quota
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: gintra-local
  local:
    path: /mnt/gintra/organizations/<cc>/<org>
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - <zfs-node-name>
```

#### Per-org PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gintra-pvc-<cc>-<org>
  namespace: argo            # or per-org namespace
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gintra-local
  resources:
    requests:
      storage: 100Gi
  selector:
    matchLabels:
      gintra-cc: <cc>
      gintra-org: <org>
```

### Argo Workflow Template Patterns

The PVC for `<cc>/<org>` is always mounted at the path that `smi-*` scripts
resolve to: `/mnt/gintra/organizations/<cc>/<org>`. This is the only correct
mountPath — using arbitrary names like `/workspace` or `/org-data` breaks the
entire `smi-*` path chain.

#### Pattern 1 — Full org dataset access

Pod mounts the org PVC at the canonical smi-* path. All location scripts work
without changes.

```yaml
inputs:
  parameters:
    - name: cc
    - name: org
volumes:
  - name: org-data
    persistentVolumeClaim:
      claimName: "gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}"
container:
  image: <base-image>
  env:
    - name: SMI_CC
      value: "{{inputs.parameters.cc}}"
    - name: SMI_ORG
      value: "{{inputs.parameters.org}}"
    - name: SMI_WF_UUID
      value: "{{workflow.uid}}"
  volumeMounts:
    - name: org-data
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
```

Inside the container:

- `smi-organization-location $SMI_CC $SMI_ORG` → `/mnt/gintra/organizations/<cc>/<org>`
- `smi-workflow-workspace-location` → `$(smi-organization-location ...)/operations/workflows/<uuid>`

#### Pattern 2 — UUID-isolated general workspace

Pod can only access its own UUID subdirectory. The init container mounts the
full org PVC (using the base image with `smi-*` scripts) to create the UUID
directory before the main container starts. The main container then gets only
the UUID subdirectory via `subPath`, mounted at the path the workspace script
resolves to.

```yaml
inputs:
  parameters:
    - name: cc
    - name: org
volumes:
  - name: org-data
    persistentVolumeClaim:
      claimName: "gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}"
initContainers:
  - name: init-workspace
    image: <base-image>
    env:
      - name: SMI_CC
        value: "{{inputs.parameters.cc}}"
      - name: SMI_ORG
        value: "{{inputs.parameters.org}}"
      - name: SMI_WF_UUID
        value: "{{workflow.uid}}"
    command:
      - sh
      - -c
      - mkdir -p $(smi-workflow-workspace-location)
    volumeMounts:
      - name: org-data
        mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
container:
  image: <base-image>
  env:
    - name: SMI_CC
      value: "{{inputs.parameters.cc}}"
    - name: SMI_ORG
      value: "{{inputs.parameters.org}}"
    - name: SMI_WF_UUID
      value: "{{workflow.uid}}"
    - name: SMI_WORKSPACE
      value: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/workflows/{{workflow.uid}}
  volumeMounts:
    - name: org-data
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/workflows/{{workflow.uid}}
      subPath: "operations/workflows/{{workflow.uid}}"
```

Inside the container:

- `smi-workflow-workspace-location` reads `$SMI_WORKSPACE` → `/mnt/gintra/organizations/<cc>/<org>/operations/workflows/<uuid>`
- The container cannot access any sibling UUID directory (K8s subPath enforcement)
- `smi-organization-location` is NOT available in this pattern (org root not mounted)

#### Pattern 3 — UUID-isolated AI workspace

Same as Pattern 2 but under the `ai/` subtree of the org dataset.

```yaml
initContainers:
  - name: init-ai-workspace
    image: <base-image>
    env:
      - name: SMI_CC
        value: "{{inputs.parameters.cc}}"
      - name: SMI_ORG
        value: "{{inputs.parameters.org}}"
      - name: SMI_WF_UUID
        value: "{{workflow.uid}}"
    command:
      - sh
      - -c
      - mkdir -p $(smi-workflow-ai-workspace-location)
    volumeMounts:
      - name: org-data
        mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
container:
  image: <base-image>
  env:
    - name: SMI_CC
      value: "{{inputs.parameters.cc}}"
    - name: SMI_ORG
      value: "{{inputs.parameters.org}}"
    - name: SMI_WF_UUID
      value: "{{workflow.uid}}"
    - name: SMI_AI_WORKSPACE
      value: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/ai/{{workflow.uid}}
  volumeMounts:
    - name: org-data
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/ai/{{workflow.uid}}
      subPath: "operations/ai/{{workflow.uid}}"
```

#### Pattern 4 — Full org access + UUID workspace combined

Two volumeMounts from the same PVC. The full org mount gives `smi-*` scripts
complete access; the subPath mount overmounts the UUID subdirectory so writes
go to the isolated workspace. In this pattern both `smi-organization-location`
and `smi-workflow-workspace-location` work naturally via the symlink chain
without needing `$SMI_WORKSPACE`.

```yaml
initContainers:
  - name: init-workspace
    image: <base-image>
    env:
      - name: SMI_CC
        value: "{{inputs.parameters.cc}}"
      - name: SMI_ORG
        value: "{{inputs.parameters.org}}"
      - name: SMI_WF_UUID
        value: "{{workflow.uid}}"
    command:
      - sh
      - -c
      - mkdir -p $(smi-workflow-workspace-location)
    volumeMounts:
      - name: org-data
        mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
container:
  image: <base-image>
  env:
    - name: SMI_CC
      value: "{{inputs.parameters.cc}}"
    - name: SMI_ORG
      value: "{{inputs.parameters.org}}"
    - name: SMI_WF_UUID
      value: "{{workflow.uid}}"
  volumeMounts:
    - name: org-data
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
    - name: org-data
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/workflows/{{workflow.uid}}
      subPath: "operations/workflows/{{workflow.uid}}"
```

### Workspace Isolation Guarantee

```
org PVC root  =  /mnt/gintra/organizations/<cc>/<org>/
├── development/
│   └── configuration/
│       └── pki/
└── operations/
    ├── ai/
    │   ├── <uuid-D>/  ← AI pod D subPath mount at .../operations/ai/<uuid-D>  (only this visible)
    │   └── <uuid-E>/  ← AI pod E subPath mount at .../operations/ai/<uuid-E>  (only this visible)
    ├── packages/      ← pkg cache; downloader writes, installer pods mount read-only
    └── workflows/
        ├── <uuid-A>/  ← pod A subPath mount at .../operations/workflows/<uuid-A>  (only this visible)
        ├── <uuid-B>/  ← pod B subPath mount at .../operations/workflows/<uuid-B>  (only this visible)
        └── <uuid-C>/  ← pod C subPath mount at .../operations/workflows/<uuid-C>  (only this visible)
```

Paths accessed via `smi-workflow-workspace-location` and
`smi-workflow-ai-workspace-location` always resolve into this tree, consistent
with the rest of the `smi-*` path hierarchy.

### Workspace Lifecycle

| Phase          | Action                                                        | Where             |
|----------------|---------------------------------------------------------------|-------------------|
| Workflow start | Init container: `mkdir -p $(smi-workflow-workspace-location)` | K8s initContainer |
| Workflow run   | Pod uses `$(smi-workflow-workspace-location)`                 | main container    |
| Workflow end   | Exit handler archives or deletes UUID directory               | Argo exit handler |

Exit handler template (archive example):

```yaml
onExit: cleanup-workspace
templates:
  - name: cleanup-workspace
    volumes:
      - name: org-data
        persistentVolumeClaim:
          claimName: "gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}"
    container:
      image: <base-image>
      env:
        - name: SMI_CC
          value: "{{inputs.parameters.cc}}"
        - name: SMI_ORG
          value: "{{inputs.parameters.org}}"
        - name: SMI_WF_UUID
          value: "{{workflow.uid}}"
      command:
        - sh
        - -c
        - |
          ARCHIVE=$(smi-organization-location ${SMI_CC} ${SMI_ORG})/operations/workflows/archive
          mkdir -p ${ARCHIVE}
          mv $(smi-workflow-workspace-location) ${ARCHIVE}/
      volumeMounts:
        - name: org-data
          mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}
```

### Scripts — Planned and Modified

#### New scripts

| Script                               | Purpose                                                                                                                  |
|--------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `smi-k8s-pvc-name <cc> <org>`        | Outputs PVC name `gintra-pvc-<cc>-<org>` for use in templates                                                            |
| `smi-k8s-org-pv-create <cc> <org>`   | Generates and applies PV manifest for the org dataset                                                                    |
| `smi-k8s-org-pvc-create <cc> <org>`  | Generates and applies PVC manifest bound to the org PV                                                                   |
| `smi-k8s-org-provision <cc> <org>`   | Full setup: ZFS dataset + PV + PVC in one call                                                                           |
| `smi-zfs-org-create <cc> <org>`      | Creates ZFS dataset `tank/organizations/<cc>/<org>` if not yet existing                                                  |
| `smi-workflow-workspace-location`    | Returns `$(smi-organization-location <cc> <org>)/operations/workflows/<uuid>`, or `$SMI_WORKSPACE` if set (UUID-only mount pattern) |
| `smi-workflow-ai-workspace-location` | Returns `$(smi-organization-location <cc> <org>)/operations/ai/<uuid>`, or `$SMI_AI_WORKSPACE` if set                               |
| `smi-packages-shared-location <cc> <org>` | Returns `$(smi-organization-location <cc> <org>)/operations/packages` (or `$SMI_SHARED_PACKAGES_DIR`); used to set `SMI_HOME_PACKAGES_DIR` in pod templates |
| `smi-k8s-packages-provision <cc> <org>`   | One-time per-org setup: creates `operations/packages` directory (or ZFS sub-dataset) + PV + PVC for the org's package cache                                 |

#### Existing scripts — no changes required

The existing `smi-organization-location`, `smi-gintra-location`,
`smi-gintra-mount-location` etc. already accept `<cc>` and `<org>` as
parameters and are generic. They work inside containers as-is once the volume
is mounted at `/mnt/gintra`.

#### `smi-k8s-org-provision` — planned logic

```
1. smi-zfs-org-create <cc> <org>
     → zfs create -p tank/organizations/<cc>/<org>
2. Generate PV YAML (from template) → kubectl apply -f -
3. Generate PVC YAML (from template) → kubectl apply -f -
4. Wait for PVC to bind (kubectl wait pvc/gintra-pvc-<cc>-<org> --for=condition=Bound)
```

#### `smi-k8s-pvc-name` — planned implementation

```sh
#!/bin/sh
CC=${1}
ORG=${2}
echo "gintra-pvc-${CC}-${ORG}"
exit 0
```

#### `smi-workflow-workspace-location` — planned implementation

Uses `smi-organization-location` as its base so the path is always consistent
with the rest of the `smi-*` hierarchy. Falls back to `$SMI_WORKSPACE` when the
full org PVC is not mounted (UUID-only subPath pattern).

```sh
#!/bin/sh
CC=${1:-${SMI_CC}}
ORG=${2:-${SMI_ORG}}
UUID=${3:-${SMI_WF_UUID}}
if [ -n "${SMI_WORKSPACE}" ] && [ $# -eq 0 ]; then
    echo "${SMI_WORKSPACE}"
    exit 0
fi
echo "$(smi-organization-location ${CC} ${ORG})/operations/workflows/${UUID}"
exit 0
```

#### `smi-workflow-ai-workspace-location` — planned implementation

```sh
#!/bin/sh
CC=${1:-${SMI_CC}}
ORG=${2:-${SMI_ORG}}
UUID=${3:-${SMI_WF_UUID}}
if [ -n "${SMI_AI_WORKSPACE}" ] && [ $# -eq 0 ]; then
    echo "${SMI_AI_WORKSPACE}"
    exit 0
fi
echo "$(smi-organization-location ${CC} ${ORG})/operations/ai/${UUID}"
exit 0
```

### Open Questions

- **Quota per org**: ZFS datasets support `refquota`. Should `smi-k8s-org-provision`
  accept a quota parameter and call `zfs set refquota=<size> tank/organizations/<cc>/<org>`?

- **Namespace per org**: Should PVCs live in a shared `argo` namespace or a
  per-org Kubernetes namespace? Per-org namespace gives stronger RBAC isolation.

- **AI sub-dataset**: Should `ai/` be a plain directory inside the org dataset
  or a separate ZFS dataset (`tank/organizations/<cc>/<org>/operations/ai`)? A separate
  dataset allows independent snapshots and quotas for AI data.

- **Workspace cleanup**: Archive vs delete on workflow exit? Who triggers cleanup
  for failed/cancelled workflows?

- **NFS vs hostPath for multi-node K3S**: If the cluster grows beyond one node,
  per-org PVs backed by NFS are needed. The `smi-k8s-org-pv-create` script
  should support a `--backend nfs|local` flag.

- **StorageClass**: A dedicated `gintra-local` StorageClass (with
  `volumeBindingMode: WaitForFirstConsumer`) should be defined once and reused
  by all per-org PVCs.

### Shared Packages Dataset

#### Concept

Package binaries (archives, installers) are large and slow to download.
Downloading the same package once per pod wastes bandwidth and time. Instead
a single ZFS dataset holds all downloaded packages and is mounted read-only
into every pod that needs to install from it. A dedicated Argo WF step
downloads packages into this shared dataset once; all subsequent pods install
from the cache without downloading again.

Package definition files (`.package` scripts) stay in the base image at
`/opt/setmy.info/lib/packages` — they are small and version-controlled.
Only the downloaded binaries live in the shared dataset.

#### ZFS Dataset

```
tank/organizations/<cc>/<org>/operations/packages       # per-org package cache (optional sub-dataset)
```

This is a plain directory inside the org dataset by default. Creating it as an
explicit ZFS sub-dataset enables independent quotas and snapshots for the
package cache.

```bash
# As a plain directory (simplest):
mkdir -p /mnt/gintra/organizations/<cc>/<org>/operations/packages

# As a dedicated ZFS sub-dataset (optional, for quota/snapshot control):
sudo zfs create -p tank/organizations/<cc>/<org>/operations/packages
```

#### How smi-* Scripts Are Redirected

`packages.sh` sets `HOME_PACKAGES_DIR` by calling `smi-home-packages-location`.
That script already supports `$SMI_HOME_PACKAGES_DIR`:

```sh
# smi-home-packages-location (existing script)
if [ -z "${SMI_HOME_PACKAGES_DIR}" ]; then
    SMI_HOME_PACKAGES_DIR="$(smi-home-location)/packages"
fi
echo "${SMI_HOME_PACKAGES_DIR}"
```

Setting `SMI_HOME_PACKAGES_DIR=/mnt/gintra/organizations/<cc>/<org>/operations/packages` in the pod environment
redirects both `smi-download-package` and `smi-install-package` to the shared
dataset. No script changes required.

`smi-download` already skips files that exist on disk, so re-running the
download workflow is safe and idempotent.

#### New script: `smi-packages-shared-location` (planned)

Returns the canonical shared packages path. Consistent with other `smi-*`
location scripts and usable both on the host and inside containers.

```sh
#!/bin/sh
CC=${1:-${SMI_CC}}
ORG=${2:-${SMI_ORG}}
if [ -n "${SMI_SHARED_PACKAGES_DIR}" ]; then
    echo "${SMI_SHARED_PACKAGES_DIR}"
    exit 0
fi
echo "$(smi-organization-location ${CC} ${ORG})/operations/packages"
exit 0
```

Output: `/mnt/gintra/organizations/<cc>/<org>/operations/packages`

Used to set `SMI_HOME_PACKAGES_DIR` in pod templates:

```yaml
env:
  - name: SMI_HOME_PACKAGES_DIR
    value: /mnt/gintra/organizations/<cc>/<org>/operations/packages   # or: $(smi-packages-shared-location)
```

#### PV / PVC for Packages

Packages are per-org. The PVC name follows the same `<cc>-<org>` pattern as
the org PVC. The downloader pod mounts it `ReadWrite`; installer pods mount
it `ReadOnly`. On single-node K3S the org PVC itself (`gintra-pvc-<cc>-<org>`)
already covers the `operations/packages` subdirectory via `subPath` — a
separate packages PVC is only needed when the packages path must be mounted
independently (e.g. in multi-node NFS setups or when the full org PVC is not
available).

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gintra-pv-<cc>-<org>-packages
  labels:
    gintra-cc: <cc>
    gintra-org: <org>
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: <nfs-server-ip>
    path: /mnt/gintra/organizations/<cc>/<org>/operations/packages
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gintra-pvc-<cc>-<org>-packages
  namespace: argo
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
  selector:
    matchLabels:
      gintra-cc: <cc>
      gintra-org: <org>
```

For single-node K3S without NFS, use the org PVC with `subPath: operations/packages`
instead of a dedicated packages PVC.

#### Argo WF: Download Step

A dedicated workflow (or workflow step) runs with write access and downloads
any missing packages. Because `smi-download` is idempotent this step can be
re-run safely to refresh the cache.

```yaml
- name: download-packages
  inputs:
    parameters:
      - name: packages       # space-separated list, e.g. "groovy gradle"
  volumes:
    - name: pkg-store
      persistentVolumeClaim:
        claimName: "gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}-packages"
  container:
    image: <base-image>
    env:
      - name: SMI_CC
        value: "{{inputs.parameters.cc}}"
      - name: SMI_ORG
        value: "{{inputs.parameters.org}}"
      - name: SMI_HOME_PACKAGES_DIR
        value: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/packages
    command:
      - sh
      - -c
      - smi-download-package {{inputs.parameters.packages}}
    volumeMounts:
      - name: pkg-store
        mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/packages
```

#### Pod: Install from Shared Cache

Every pod that needs packages mounts the PVC read-only and runs
`smi-install-package`. It reads binaries from the shared dataset without
downloading anything.

```yaml
volumes:
  - name: pkg-store
    persistentVolumeClaim:
        claimName: "gintra-pvc-{{inputs.parameters.cc}}-{{inputs.parameters.org}}-packages"
        readOnly: true
container:
  env:
    - name: SMI_HOME_PACKAGES_DIR
      value: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/packages
  volumeMounts:
    - name: pkg-store
      mountPath: /mnt/gintra/organizations/{{inputs.parameters.cc}}/{{inputs.parameters.org}}/operations/packages
      readOnly: true
```

Inside the container:

```sh
smi-install-package groovy       # reads from /mnt/gintra/organizations/<cc>/<org>/operations/packages, no download
smi-install-package gradle cmake # multiple packages in one call
```

#### New script: `smi-k8s-packages-provision` (planned)

Wraps the one-time setup of the packages dataset and its PV/PVC:

```
1. mkdir -p /mnt/gintra/organizations/<cc>/<org>/operations/packages
   (or: zfs create -p tank/organizations/<cc>/<org>/operations/packages for sub-dataset)
2. Apply PV manifest for gintra-pv-<cc>-<org>-packages → kubectl apply -f -
3. Apply PVC manifest for gintra-pvc-<cc>-<org>-packages → kubectl apply -f -
4. Wait for PVC to bind
```

#### Packages Dataset Lifecycle

| Action                    | Who                         | Access mode |
|---------------------------|-----------------------------|-------------|
| Initial download          | Argo download-packages step | ReadWrite   |
| Refresh / add new package | Same download step          | ReadWrite   |
| Install in pod            | Any pod                     | ReadOnly    |
| Cleanup old versions      | Manual or cron job          | ReadWrite   |

---

### Design Notes and Rationale

#### Why subPath and not a separate PVC per workflow run

Creating a fresh PVC for every workflow run would require dynamic ZFS dataset
provisioning (e.g. democratic-csi) and leaves many short-lived PV/PVC objects
in the cluster to clean up. Using `subPath: operations/workflows/<uuid>` on a
single pre-existing per-org PVC achieves the same isolation with no extra K8s objects
and no provisioner dependency. The UUID subdirectory is just a directory on the
ZFS dataset.

#### Why the init container is mandatory

Kubernetes does not create the `subPath` directory automatically. If the
directory does not exist when the main container starts, the mount fails and the
pod goes into `CreateContainerError`. The init container mounts the full org
PVC and runs `mkdir -p $(smi-workflow-workspace-location)` — using the same
`smi-*` script that the main container uses — so the path is always consistent.
The init container must use the base image (not a minimal image like alpine)
so that `smi-*` scripts are available.

#### Why existing smi-* scripts need no changes

The scripts already resolve all paths through `smi-gintra-location` →
`/var/opt/setmy.info/gintra` → symlink → `/mnt/gintra`. As long as the
container has:

- the symlink baked into the base image (`/var/opt/setmy.info/gintra -> /mnt/gintra`)
- the PVC mounted at `/mnt/gintra`

every `smi-organization-location <cc> <org>`, `smi-persons-location`, etc.
resolves to real data without any modification. This was a deliberate design
choice in the original FHS-based path layout.

#### FHS structure inside UUID-only pods

In Pattern 2 and 3 the org PVC root is not mounted — only the UUID workspace
subdirectory is mounted at its full canonical path. However, the parent
directories (`/mnt/gintra/organizations/<cc>/<org>/operations/workflows/`) are just
empty path components created by the container's own filesystem overlay; they
do not need to contain real data for `smi-*` scripts to work.

When the mountPath is `/mnt/gintra/organizations/<cc>/<org>/operations/workflows/<uuid>`,
the container automatically has those parent directories as empty dirs in its
overlayfs. This means:

- `smi-workflow-workspace-location` (via `$SMI_WORKSPACE`) resolves correctly
- `smi-organization-location $SMI_CC $SMI_ORG` resolves to the parent path,
  which exists as an empty directory — safe to read, nothing to write to
- Any `smi-*` script that only needs to know the path string (not read data
  from the org root) works without modification

Scripts that need to actually read shared org data (config files, person
records, etc.) require Pattern 1 or 4 where the full org PVC is mounted.

#### Internal use (non-Argo containers)

The same volume mount approach applies to any container that is not an Argo
workflow — regular Deployments, Jobs, CronJobs. Mount the org PVC at
`/mnt/gintra` and the full `smi-*` toolchain is available. The base image
symlink is the only pre-requisite. Argo WF is not special; it just adds the
UUID workspace isolation layer on top.

#### AI workspace separation rationale

AI workloads often produce large intermediate artefacts (model checkpoints,
embeddings, generated files). Keeping these under `operations/ai/<uuid>/`
rather than `operations/workflows/<uuid>/` allows:

- separate quota tracking if `operations/ai/` becomes a ZFS sub-dataset later
- independent snapshot/backup policies for AI artefacts vs general workflow output
- clear separation when browsing the org dataset manually

The `operations/` parent groups all runtime workload output together, separating
it from long-lived configuration under `development/`.

The choice between `operations/ai/` as a plain directory vs a dedicated ZFS
sub-dataset (`tank/organizations/<cc>/<org>/operations/ai`) is left as an open question —
both work with the subPath mechanism.

#### StorageClass definition (to be created once)

All per-org PVCs use `storageClassName: gintra-local`. This class must be
defined in the cluster before any PVC is created:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gintra-local
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
```

`WaitForFirstConsumer` delays PV binding until a pod is scheduled, which is
important for local storage so the pod lands on the correct node.

#### Org onboarding sequence

When a new organisation is added the following must happen once, in order:

```
1. smi-zfs-org-create <cc> <org>
      → creates ZFS dataset on the host

2. smi-k8s-org-pv-create <cc> <org>
      → applies PV manifest to cluster (references host path)

3. smi-k8s-org-pvc-create <cc> <org>
      → applies PVC manifest, binds to the PV

4. (optional) zfs set refquota=<size> tank/organizations/<cc>/<org>
      → enforce storage limit per org at ZFS level
```

Steps 1–3 are wrapped by `smi-k8s-org-provision <cc> <org>`.
After this the org PVC is ready and any Argo workflow or regular container
referencing `gintra-pvc-<cc>-<org>` will work.

#### Environment variables passed to pods

Pods should receive these environment variables so that scripts and application
code can identify their execution context without hard-coding values:

| Variable                | Value                                                   | Source                     |
|-------------------------|---------------------------------------------------------|----------------------------|
| `SMI_CC`                | country code                                            | Argo input parameter       |
| `SMI_ORG`               | organisation short name                                 | Argo input parameter       |
| `SMI_WF_UUID`           | workflow UID                                            | `{{workflow.uid}}`         |
| `SMI_WORKSPACE`         | `/mnt/gintra/organizations/<cc>/<org>/operations/workflows/<uuid>` | set in pattern 2 pods      |
| `SMI_AI_WORKSPACE`      | `/mnt/gintra/organizations/<cc>/<org>/operations/ai/<uuid>`        | set in pattern 3 pods      |
| `SMI_HOME_PACKAGES_DIR` | `/mnt/gintra/organizations/<cc>/<org>/operations/packages`                                  | set when using org pkg cache |

`smi-workflow-workspace-location` and `smi-workflow-ai-workspace-location`
read `$SMI_WORKSPACE` / `$SMI_AI_WORKSPACE` so the mount path can be
overridden without changing scripts. `smi-home-packages-location` reads
`$SMI_HOME_PACKAGES_DIR` to redirect package operations to the shared dataset.

### Summary Flow

```
Argo WF triggered with params: cc=<cc>, org=<org>
  │
  ├─ Pre-conditions (one-time setup):
  │   gintra-pvc-<cc>-<org>          created by smi-k8s-org-provision
  │   gintra-pvc-<cc>-<org>-packages created by smi-k8s-packages-provision <cc> <org>
  │
  ├─ initContainer:
  │   mount org PVC → /mnt/gintra/organizations/<cc>/<org>
  │   mkdir -p $(smi-workflow-workspace-location)
  │
  ├─ main container:
  │   mount org PVC → /mnt/gintra/organizations/<cc>/<org>                           (full access)
  │   mount org PVC → .../operations/workflows/<uuid>  subPath operations/workflows/<uuid> (workspace)
  │   mount packages PVC → .../operations/packages  subPath operations/packages  (read-only)
  │   env: SMI_CC, SMI_ORG, SMI_WF_UUID
  │   env: SMI_WORKSPACE=.../operations/workflows/<uuid>
  │   env: SMI_HOME_PACKAGES_DIR=.../organizations/<cc>/<org>/operations/packages
  │   smi-install-package <name>  ← installs from shared packages PVC
  │   smi-* path scripts work normally via symlink chain
  │
  └─ onExit: archive or delete operations/workflows/<uuid>
```

---

## Quick Reference Card

```
Pool:    tank  (mirror: two disks)
Root:    /mnt/gintra                           (smi-gintra-mount-location)
Data:    /mnt/gintra/organizations/<cc>/<org>  (ZFS dataset per organisation)

Logical: /var/opt/setmy.info/gintra -> /mnt/gintra   (symlink, FHS)
         ├── organizations/
         │   └── <cc>/
         │       └── <org>/               ← ZFS dataset tank/organizations/<cc>/<org>
         │           ├── development/
         │           │   └── configuration/pki/
         │           └── operations/
         │               ├── ai/          ← AI workflow workspaces
         │               ├── packages/    ← per-org pkg cache
         │               └── workflows/   ← general workflow workspaces
         └── persons/

NFS:     /mnt/gintra/organizations/<cc>/<org> *(rw,sync,no_root_squash)
         reload:  sudo exportfs -ra
```
