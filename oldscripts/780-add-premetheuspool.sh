#!/usr/bin/env bash
# 780-add-premetheuspool.sh — 

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }


set -x
DEVICE="sdg"
NAME="prometheus"
POOL_NAME="prometheuspool"
MOUNTPOINT="/srv/prometheus-data"
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
if ! zfs list "${POOL_NAME}/data" >/dev/null 2>&1; then
    set -x
    sudo mkdir -p "${MOUNTPOINT}"
    sudo zfs create "${POOL_NAME}/data" -o mountpoint="${MOUNTPOINT}"
    set +x
fi


set -x
# 6. Verify
findmnt -T ${MOUNTPOINT}
zfs list ${POOL_NAME} ${POOL_NAME}/data
sudo zpool status "${POOL_NAME}"


findmnt -T /srv/prometheus-data
zfs list prometheuspool prometheuspool/data
sudo zpool status prometheuspool


ll /srv/prometheus-data


