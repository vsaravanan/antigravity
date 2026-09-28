#!/usr/bin/env bash
# 770-add-mysqlpool.sh — 

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }


set -x
DEVICE="sds"
NAME="mysql"
POOL_NAME="mysqlpool"
MOUNTPOINT="/srv/mysql-data"
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

ll /srv/mysql-data


