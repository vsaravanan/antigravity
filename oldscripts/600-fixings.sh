#!/usr/bin/env bash
# 00b-fixings.sh — run from the HOST
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
# ---------------------------------------------------------------------------
log "==> Host-level fixes, baked in from the start this time"

# kubelet's ContainerManager needs these three GLOBAL (non-namespaced)
# sysctls to already match its desired values, or it fails inside any LXC
# container — even privileged ones — because these aren't per-namespace.
cat <<'EOF' | sudo tee /etc/sysctl.d/99-kubelet-lxc.conf
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
EOF
sudo sysctl --system

# journald straight to RAM — no persistent log accumulation on this VM at all.
sudo mkdir -p /etc/systemd/journald.conf.d
cat <<'EOF' | sudo tee /etc/systemd/journald.conf.d/99-volatile.conf
[Journal]
Storage=volatile
RuntimeMaxUse=100M
EOF
sudo systemctl restart systemd-journald

# sysstat's periodic collectors were a measurable contributor to disk churn
# in testing — not needed for a learning lab.
sudo systemctl disable --now sysstat-collect.timer sysstat-summary.timer sysstat-rotate.timer 2>/dev/null || true

