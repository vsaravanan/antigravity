#!/usr/bin/env bash
# 750-add-dockerpool.sh — run on the HOST (k8s VM), after attaching a new
# virtual disk for Docker's data. Dedicates that disk to its own ZFS pool,
# mounts Docker's data root AND Maven's .m2 cache into k8master as separate
# datasets — keeping build/image churn on its own pool, and separately
# attributable from each other, apart from cluster state on masterpool.
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }

# ---------------------------------------------------------------------------
# EDIT THIS before running — confirm with `lsblk` which device is the new,
# empty disk you attached for Docker. Do NOT guess; a wrong value here means
# zpool create wipes the wrong disk.
DEVICE="sdq"
POOL_NAME="dockerpool"
DOCKER_MOUNTPOINT="/srv/docker-data"
M2_MOUNTPOINT="/srv/m2-data"
CONTAINER="k8master"
DOCKER_DATA_PATH="/var/lib/docker"
M2_PATH="/root/.m2"   # adjust if builds run as a non-root user inside the container


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
sudo zpool list "${POOL_NAME}"

# ---------------------------------------------------------------------------
log "==> Creating separate datasets: docker data and maven .m2 cache"
if ! zfs list "${POOL_NAME}/data" >/dev/null 2>&1; then
    set -x
    sudo mkdir -p "${DOCKER_MOUNTPOINT}"
    sudo zfs create "${POOL_NAME}/data" -o mountpoint="${DOCKER_MOUNTPOINT}"
    set +x
fi
if ! zfs list "${POOL_NAME}/m2" >/dev/null 2>&1; then
    set -x
    sudo mkdir -p "${M2_MOUNTPOINT}"
    sudo zfs create "${POOL_NAME}/m2" -o mountpoint="${M2_MOUNTPOINT}"
    set +x
fi

# ---------------------------------------------------------------------------
log "==> Passing both datasets into ${CONTAINER}"
if ! lxc config device list "${CONTAINER}" | grep -q "^docker-data$"; then
    set -x
    lxc config device add "${CONTAINER}" docker-data disk \
        source="${DOCKER_MOUNTPOINT}" path="${DOCKER_DATA_PATH}"
    set +x
fi
if ! lxc config device list "${CONTAINER}" | grep -q "^m2-data$"; then
    set -x  
    lxc config device add "${CONTAINER}" m2-data disk \
        source="${M2_MOUNTPOINT}" path="${M2_PATH}"
    set +x
fi
lxc restart "${CONTAINER}"

# ---------------------------------------------------------------------------
log "==> Installing Docker Engine inside ${CONTAINER}"
lxc exec "${CONTAINER}" -- bash -c '
set -euo pipefail
apt update
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
'


# ---------------------------------------------------------------------------
log "==> Verifying both mounts landed on the dedicated pool, not masterpool"
lxc exec "${CONTAINER}" -- docker info --format "Docker Root Dir: {{.DockerRootDir}}"
lxc exec "${CONTAINER}" -- df -h "${DOCKER_DATA_PATH}" "${M2_PATH}"

log "==> Done. zfs list -r ${POOL_NAME} now shows docker/data and docker/m2"
log "    independently — build churn is fully separated from masterpool."


# Remove the device mounted at the wrong path
lxc config device remove k8master m2-data

# Re-add it at the correct path
lxc config device add k8master m2-data disk \
  source=/srv/m2-data path=/root/.m2

# Apply it
lxc restart k8master