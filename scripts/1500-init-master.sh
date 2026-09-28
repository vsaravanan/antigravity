#!/usr/bin/env bash
# 1500-init-master.sh — run INSIDE k8master after 02-node-common-setup.sh.
# k8master 4115 - 3839 = 276 mb
#   lxc file push scripts/1500-init-master.sh k8master/root/init-master.sh
#   lxc exec k8master -- bash /root/init-master.sh
#
# NOTE: kube-proxy addon is skipped here on purpose. Cilium (04-install-cilium.sh)
# replaces it entirely with an eBPF-based service data plane. The node will show
# NotReady until that script has run — that's expected, there's no CNI yet.
set -euo pipefail

MASTER_IP="192.168.100.10"
POD_CIDR="10.244.0.0/16"
K8S_VERSION="$(kubeadm version -o short)"

echo "==> Writing kubeadm config (bakes in etcd auto-compaction + quota from the start,"
echo "    instead of hitting unbounded etcd growth and patching it after the fact)"
cat > /root/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
localAPIEndpoint:
  advertiseAddress: "${MASTER_IP}"
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: "${K8S_VERSION}"
controlPlaneEndpoint: "${MASTER_IP}:6443"
networking:
  podSubnet: "${POD_CIDR}"
apiServer:
  certSANs:
    - "${MASTER_IP}"
etcd:
  local:
    extraArgs:
      - name: auto-compaction-mode
        value: "periodic"
      - name: auto-compaction-retention
        value: "5m"
      - name: quota-backend-bytes
        value: "2147483648"
EOF

echo "==> kubeadm init (control-plane endpoint ${MASTER_IP}, no kube-proxy — Cilium replaces it,"
echo "    etcd auto-compaction+quota baked in — see /root/kubeadm-config.yaml)"
kubeadm init \
  --config=/root/kubeadm-config.yaml \
  --skip-phases=addon/kube-proxy \
  --ignore-preflight-errors=Swap,SystemVerification,Mem,FileContent--proc-sys-net-bridge-bridge-nf-call-iptables

echo "==> Configuring kubectl for root"
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown "$(id -u)":"$(id -g)" /root/.kube/config

echo "==> Generating the worker join command -> /root/join-command.sh"
kubeadm token create --print-join-command > /root/join-command.sh
chmod +x /root/join-command.sh
cat /root/join-command.sh

echo "==> Master control plane initialized (node will be NotReady until Cilium is installed)."
echo "==> Next: scripts/04-install-cilium.sh (installs the CNI + kube-proxy replacement)"
echo "==> Then pull the join command to the host with:"
echo "    lxc file pull k8master/root/join-command.sh ./join-command.sh"
echo "==> and run scripts/05-join-worker.sh"


