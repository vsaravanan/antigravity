#!/usr/bin/env bash
# 760-add-miniopool.sh — 
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }


set -x
DEVICE="sdr"
NAME="minio"
POOL_NAME="miniopool"
MOUNTPOINT_TEMP="/srv/minio-temp"
MOUNTPOINT="/srv/minio-data"
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
sudo rsync -aHAX --numeric-ids  \
    ${MOUNTPOINT_TEMP}/ \
    ${MOUNTPOINT}/


sudo du -sh ${MOUNTPOINT_TEMP}
sudo du -sh ${MOUNTPOINT}

sudo rsync -aHAXn --numeric-ids --delete \
    ${MOUNTPOINT}/ \
    ${MOUNTPOINT_TEMP}/

exit 0

# 6. Switch to final mountpoint
sudo zfs set mountpoint=${MOUNTPOINT} "${POOL_NAME}/data"

# 7. Verify
findmnt -T ${MOUNTPOINT}
zfs list
sudo zpool status "${POOL_NAME}"

# 8. Start MinIO
docker start minio

# 9. Verify
docker ps
docker logs minio

