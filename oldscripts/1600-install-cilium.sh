#!/usr/bin/env bash
# 1600-install-cilium.sh — run INSIDE k8master after 1500-init-master.sh.
# k8master 5216 - 4115 = 101 mb
#   lxc file push scripts/1600-install-cilium.sh k8master/root/install-cilium.sh
#   lxc exec k8master -- bash /root/install-cilium.sh
#
# Installs Cilium as the CNI with full eBPF kube-proxy replacement
# (replaces Flannel + kube-proxy from the old setup).
set -euo pipefail

export KUBECONFIG=/root/.kube/config

MASTER_IP="192.168.100.10"
API_SERVER_PORT="6443"
CILIUM_VERSION="1.20.1"

echo "==> Adding the Cilium Helm repo"
helm repo add cilium https://helm.cilium.io/
helm repo update

echo "==> Installing Cilium ${CILIUM_VERSION} with kube-proxy replacement enabled"
helm install cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost="${MASTER_IP}" \
  --set k8sServicePort="${API_SERVER_PORT}" \
  --set ipam.mode=kubernetes \
  --set bpf.masquerade=true \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set prometheus.enabled=true

echo "==> Waiting for Cilium to roll out"
kubectl -n kube-system rollout status daemonset/cilium --timeout=180s

echo "==> Waiting for the master node to go Ready (Cilium is now the CNI)"
kubectl wait --for=condition=Ready node --all --timeout=180s || true

echo "==> Confirming kube-proxy replacement is active"
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --brief | grep -i "kubeproxyreplacement" || true

echo "==> Cilium install complete. Hubble UI (traffic visibility) can be reached with:"
echo "    kubectl -n kube-system port-forward svc/hubble-ui 12000:80"
echo "==> Next: pull the join command and run scripts/1700-join-worker.sh from the host."


