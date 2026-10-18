#!/usr/bin/env bash
# 790-add-hello-ui.sh — 

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }


set -x
DEVICE="sdu"
NAME="hello-ui"
POOL_NAME="${NAME}pool"
POOL_DATA="${POOL_NAME}/data"
MOUNTPOINT="/srv/${NAME}-data"
set +x

# ---------------------------------------------------------------------------
log "==> Creating ${POOL_NAME} on /dev/${DEVICE} (autotrim + lz4 compression from creation)"
if zpool list "${POOL_NAME}" >/dev/null 2>&1; then
  warn "Pool ${POOL_NAME} already exists, skipping create"
else
  set -x
  sudo zpool create -o ashift=12 -o autotrim=on -O compression=lz4 \
  -O mountpoint=none "${POOL_NAME}" "/dev/${DEVICE}"
  set +x
fi
set -x
sudo zpool list "${POOL_NAME}"
sudo zpool status "${POOL_NAME}"
zpool get autotrim "${POOL_NAME}"
set +x
# ---------------------------------------------------------------------------
log "==> Creating separate datasets: ${NAME} data "
if ! zfs list "${POOL_DATA}" >/dev/null 2>&1; then
    set -x
    sudo mkdir -p "${MOUNTPOINT}"
    sudo zfs create "${POOL_DATA}" -o mountpoint="${MOUNTPOINT}"
    set +x
fi


TOOL_POOLS=(${POOL_NAME})


# ---------------------------------------------------------------------------
log "==> Passing every tool-specific directory into k8worker1 for later PersistentVolume use"
for pool in "${TOOL_POOLS[@]}"; do
  name="${pool%pool}"
  log "lxc config device add k8worker1 ${name}-data disk source=/srv/${name}-data path=/mnt/${name}-data"
  lxc config device add k8worker1 "${name}-data" disk \
    source="/srv/${name}-data" path="/mnt/${name}-data"
done


set -x
# 6. Verify
findmnt -T ${MOUNTPOINT}
zfs list ${POOL_NAME} ${POOL_DATA}
sudo zpool status "${POOL_NAME}"

ll ${MOUNTPOINT}


