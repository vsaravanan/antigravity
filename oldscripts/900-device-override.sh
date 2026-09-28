#!/usr/bin/env bash
# 00k-device-override.sh — run from the HOST

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }

log "==> Pinning each container's root disk to its dedicated pool (profile's root device is a template pointing at 'default' — override it per instance)"
log "lxc config device override k8master root pool=master-pool"
lxc config device override k8master root pool=master-pool || true
log "lxc config device override k8worker1 root pool=worker1-pool"
lxc config device override k8worker1 root pool=worker1-pool || true

lxc config set k8master security.privileged true
lxc config set k8master security.nesting true
lxc config set k8worker1 security.privileged true
lxc config set k8worker1 security.nesting true

log "==> Pinning k8master to 192.168.100.10 (every downstream script hardcodes this address — DHCP alone won't guarantee it)"
log "lxc config device override k8master eth0 ipv4.address=192.168.100.10"
lxc config device override k8master eth0 ipv4.address=192.168.100.10 || true
log "lxc config device override k8worker1 eth0 ipv4.address=192.168.100.11"
lxc config device override k8worker1 eth0 ipv4.address=192.168.100.11 || true

lxc restart k8master
lxc restart k8worker1


# ---------------------------------------------------------------------------
log "==> linking 15 containers to k8master"


TOOL_POOLS=(kongpool jaegerpool prometheuspool grafanapool lokipool vaultpool \
            gitlabpool keycloakpool kafkapool redispool postgrespool opensearchpool)


# ---------------------------------------------------------------------------
log "==> Passing every tool-specific directory into k8master for later PersistentVolume use"
for pool in "${TOOL_POOLS[@]}"; do
  name="${pool%pool}"
  log "lxc config device add k8master ${name}-data disk source=/srv/${name}-data path=/mnt/${name}-data"
  lxc config device add k8master "${name}-data" disk \
    source="/srv/${name}-data" path="/mnt/${name}-data"
done
lxc config device show k8master
lxc config device show k8worker1

log "==> Done. Containers:"
lxc list

lxc storage list || true
lxc network list || true
lxc profile list || true
lxc image list || true
sudo zpool list || true

log "==> Next: push and run 02-node-common-setup.sh inside BOTH k8master and k8worker1"


