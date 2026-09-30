#!/usr/bin/env bash
# fix-cilium-lb.sh
#
# Run whenever the Kong LoadBalancer IP is unreachable after a node/host
# restart, but NodePort access and `kubectl` both work fine.
#
# Root cause: Cilium's eBPF datapath for the LoadBalancer service can go
# stale/unsynced from its control-plane state after an abrupt node restart.
# `cilium-dbg service list` shows the LB entry correctly even when it's
# actually broken, and ARP for the LB IP still resolves fine — so neither
# is a reliable diagnostic for this failure mode. Restarting both Cilium
# agents together resolves it; restarting just one is not sufficient.
#
# Usage: ./fix-cilium-lb.sh [LB_IP] [PATH]
#   LB_IP  defaults to 192.168.100.240
#   PATH   defaults to /auth/  (any path Kong routes and returns 2xx/3xx for)
# ./fix-cilium-lb.sh                              # checks 192.168.100.240/auth/ by default
# ./fix-cilium-lb.sh 192.168.100.240 /echo         # or check a different path/route

set -euo pipefail

LB_IP="${1:-192.168.100.240}"
CHECK_PATH="${2:-/auth/}"
URL="https://${LB_IP}${CHECK_PATH}"

check() {
  curl -k -sf -o /dev/null -w '%{http_code}' "$URL" --max-time 3 2>/dev/null || echo "000"
}

echo "== Testing LB IP: ${URL} =="
code="$(check)"

if [[ "$code" =~ ^[23] ]]; then
  echo "LB IP already reachable (HTTP ${code}). Nothing to do."
  exit 0
fi

echo "LB IP unreachable (HTTP ${code:-timeout}). Restarting Cilium agents (both nodes)..."
kubectl -n kube-system rollout restart daemonset cilium
kubectl -n kube-system rollout status daemonset cilium --timeout=120s

echo "== Waiting for agents to settle =="
sleep 5

echo "== Retesting =="
code="$(check)"
if [[ "$code" =~ ^[23] ]]; then
  echo "Fixed — LB IP now reachable (HTTP ${code})."
  exit 0
else
  echo "Still unreachable (HTTP ${code:-timeout}) after Cilium restart."
  echo "This is no longer the known Cilium-datapath issue — fall back to the"
  echo "full diagnostic sequence: node health (zpool status, kubectl get nodes),"
  echo "Kong pod health, NodePort bypass test, then ARP/iptables checks."
  exit 1
fi