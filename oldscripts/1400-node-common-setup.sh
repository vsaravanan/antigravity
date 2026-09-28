#!/usr/bin/env bash
# 1400-node-common-setup.sh — run INSIDE each container (k8master AND k8worker1).
# k8worker1 2508 - 1842 = 666 mb
#   lxc file push scripts/1400-node-common-setup.sh k8master/root/setup.sh
#   lxc exec k8master -- bash /root/setup.sh
#   lxc file push scripts/1400-node-common-setup.sh k8worker1/root/setup.sh
#   lxc exec k8worker1 -- bash /root/setup.sh
#
# Installs containerd + kubeadm/kubelet/kubectl 1.36.x on Ubuntu 26.04.
#

set -euxo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
err()  { echo -e "\033[1;31m[ERR]\033[0m   $*" >&2; exit 1; }

# 1.36 is the newest branch with a comfortable EOL runway as of Sept 2026.
# (1.33 is fully EOL, 1.34 goes EOL Oct 27 2026 — don't use either for a
# fresh cluster.) Check https://kubernetes.io/releases/ before you build.
K8S_MINOR="1.36"

source /etc/os-release

log "==> Disabling swap (kubelet requires this)"
swapoff -a
# Comment out the swap line rather than deleting it, so 10-undo-kubelet-install.sh
# can restore it cleanly by uncommenting.
sed -i '/ swap /s/^/#/' /etc/fstab || true

log "==> Loading kernel modules required by kube-proxy / CNI"
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay || true
modprobe br_netfilter || true

log "==> Sysctl params required for Kubernetes networking"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

log "==> Installing containerd"
apt update
apt install -y ca-certificates curl gnupg apt-transport-https gpg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y containerd.io

log "==> Configuring containerd for the systemd cgroup driver (required by kubelet)"
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

log "==> Adding the Kubernetes apt repo for v${K8S_MINOR}"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/Release.key" | \
  gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MINOR}/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

log "==> Capping journald size (unbounded logs were the #1 cause of runaway disk growth in testing)"
mkdir -p /etc/systemd/journald.conf.d
cat <<EOF | tee /etc/systemd/journald.conf.d/99-size-cap.conf
[Journal]
SystemMaxUse=200M
RuntimeMaxUse=100M
EOF
systemctl restart systemd-journald
journalctl --vacuum-size=200M || true

log "==> Installing Helm (needed on the master for Cilium/observability stack installs)"
if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

log "==> Enabling kubelet"
systemctl enable --now kubelet

log "==> Versions installed:"
kubeadm version
kubelet --version
kubectl version --client
helm version

log "==> Node bootstrap complete on $(hostname). Next:"
log "    master:  scripts/03-init-master.sh, then scripts/04-install-cilium.sh"
log "    worker:  scripts/05-join-worker.sh <join-command-from-master>"


