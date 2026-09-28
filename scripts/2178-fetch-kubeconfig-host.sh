#!/usr/bin/env bash
# 2178-fetch-kubeconfig-host.sh — run on the HOST.
# Pulumi's kubernetes provider (and kubectl, if you install it here) both
# discover a cluster the same way: $KUBECONFIG env var, falling back to
# ~/.kube/config. Neither has magic awareness of k8master — this script is
# what actually connects them.
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }

mkdir -p ~/.kube
lxc file pull k8master/root/.kube/config ~/.kube/config

log "==> Kubeconfig copied. Confirming it points at the expected address:"
grep "server:" ~/.kube/config

log "==> Testing raw network reachability to the API server (independent of auth)"
curl -k -sS -o /dev/null -w "HTTP %{http_code}\n" https://192.168.100.10:6443/version \
  || { echo "Cannot reach 192.168.100.10:6443 from the host — check the k8sbr0 bridge before going further."; exit 1; }

log "==> Done. Pulumi's kubernetes provider will now pick this up automatically."
log "    export KUBECONFIG=~/.kube/config   # add to ~/.bashrc if you want this permanent"
log "    (Optional, for manual verification) install kubectl on the host and run: kubectl get nodes"