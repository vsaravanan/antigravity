#!/usr/bin/env bash
# 00i-create-containers.sh — run from the HOST

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }

# ---------------------------------------------------------------------------
log "==> Initializing LXD via preseed (default pool = datapool, dedicated pools for each container)"
lxd init --preseed < /data/k8s-lxd-lab/grok/k8s-preseed.yaml


# ---------------------------------------------------------------------------
log "==> Copying the Ubuntu 26.04 image locally (avoids re-fetching from the remote for each container)"
if ! lxc image info ubuntu2604 >/dev/null 2>&1; then
  log "lxc image copy ubuntu:26.04 local: --alias ubuntu2604"
  lxc image copy ubuntu:26.04 local: --alias ubuntu2604
fi

log "==> Launching k8master and k8worker1, each on its own dedicated pool, with the k8s-base profile (privileged+nesting already applied at creation — no post-launch config needed)"
log "lxc launch local:ubuntu2604 k8master -s masterpool -p default -p k8s-base"
lxc launch local:ubuntu2604 k8master -s master-pool -p default -p k8s-base
log "lxc launch local:ubuntu2604 k8worker1 -s worker1-pool -p default -p k8s-base"
lxc launch local:ubuntu2604 k8worker1 -s worker1-pool -p default -p k8s-base

