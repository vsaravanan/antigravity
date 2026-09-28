#!/usr/bin/env bash
# 06-cilium-lb-ipam.sh — run INSIDE k8master, after 04-install-cilium.sh.
# Gives Cilium a pool of IPs to hand out to Services of type LoadBalancer,
# since there's no cloud LB controller on a bare LXC cluster. Without this,
# any LoadBalancer Service (including Kong's proxy) sits at <pending> forever.
set -euo pipefail
export KUBECONFIG=/root/.kube/config

# Adjust this range to a slice of your LXC bridge subnet that's NOT handed
# out by DHCP/lxd (check `lxc network show lxdbr0` for the subnet in use).
# MASTER_IP is 192.168.100.10 in these scripts, so we reserve a small block
# at the top of that /24.
LB_RANGE_START="192.168.100.240"
LB_RANGE_END="192.168.100.250"

cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2"
kind: CiliumLoadBalancerIPPool
metadata:
  name: lab-pool
spec:
  blocks:
    - start: "${LB_RANGE_START}"
      stop: "${LB_RANGE_END}"
EOF

echo "==> Enabling L2 announcements so these IPs are actually reachable on the LAN"
cat <<EOF | kubectl apply -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumL2AnnouncementPolicy
metadata:
  name: lab-l2-policy
spec:
  loadBalancerIPs: true
  interfaces:
    - ^eth[0-9]+
  nodeSelector:
    matchLabels: {}
EOF

kubectl get ciliumloadbalancerippool
echo "==> LB pool ready: ${LB_RANGE_START} - ${LB_RANGE_END}"