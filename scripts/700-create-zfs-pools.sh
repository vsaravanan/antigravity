#!/usr/bin/env bash
# 00d-create-pools.sh — run ONCE on the freshly-installed host VM, before
# any of the 02+ scripts. Builds the entire storage layer from scratch:
#   - host-level fixes baked in from the start (not retrofitted this time)
#   - one dedicated ZFS pool per device, per the mapping below
#   - LXD initialized via preseed (no auto-created default pool)
#   - k8master / k8worker1 launched on their OWN dedicated pool/disk
#   - every tool-specific pool mounted into k8master at /mnt/<tool>-data,
#     ready for per-tool StorageClasses later
#
# Device mapping (confirm with `lsblk` before running — device names can
# theoretically shift on reboot, though ZFS itself is robust to this once
# pools exist; this only matters for the one-time `zpool create` below):
#   sdb → datapool        (LXD's own "default" pool — images, misc)
#   sdc → masterpool       → k8master container root
#   sdd → worker1pool      → k8worker1 container root
#   sde → kongpool
#   sdf → jaegerpool
#   sdg → prometheuspool
#   sdh → grafanapool
#   sdi → lokipool
#   sdj → vaultpool
#   sdk → gitlabpool
#   sdl → keycloakpool
#   sdm → kafkapool
#   sdn → redispool
#   sdo → postgrespool
#   sdp → opensearchpool
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }

# ---------------------------------------------------------------------------
log "==> Sanity check: confirm the disks look like what we expect before we destroy anything on them"
lsblk
read -rp "Does the device list above match the mapping in this script's header? (yes/no): " CONFIRM
[ "${CONFIRM}" = "yes" ] || { echo "Aborting — fix the mapping first."; exit 1; }



# ---------------------------------------------------------------------------
log "==> Creating all 15 ZFS pools with autotrim on from creation (no retrofit needed this time)"

declare -A POOLS=(
  [sdb]=datapool
  [sdc]=masterpool
  [sdd]=worker1pool
  [sde]=kongpool
  [sdf]=jaegerpool
  [sdg]=prometheuspool
  [sdh]=grafanapool
  [sdi]=lokipool
  [sdj]=vaultpool
  [sdk]=gitlabpool
  [sdl]=keycloakpool
  [sdm]=kafkapool
  [sdn]=redispool
  [sdo]=postgrespool
  [sdp]=opensearchpool
)

for dev in "${!POOLS[@]}"; do
  pool="${POOLS[$dev]}"
  if zpool list "${pool}" >/dev/null 2>&1; then
    warn "Pool ${pool} already exists, skipping create"
  else
    log "Creating ${pool} on /dev/${dev}"
    log "sudo zpool create -o ashift=12 -o autotrim=on -O compression=lz4 -O mountpoint=none ${pool} /dev/${dev}"
    sudo zpool create -o ashift=12 -o autotrim=on -O compression=lz4 -O mountpoint=none "${pool}" "/dev/${dev}"
  fi
done

zpool list

# ---------------------------------------------------------------------------
log "==> Creating a mounted dataset on each TOOL pool (not data/master/worker1 — those back LXD/containers directly)"

TOOL_POOLS=(kongpool jaegerpool prometheuspool grafanapool lokipool vaultpool \
            gitlabpool keycloakpool kafkapool redispool postgrespool opensearchpool)

for pool in "${TOOL_POOLS[@]}"; do
  name="${pool%pool}"   # kongpool -> kong
  mountpoint="/srv/${name}-data"
  if ! zfs list "${pool}/data" >/dev/null 2>&1; then
    log "sudo mkdir -p ${mountpoint}"
    sudo mkdir -p "${mountpoint}"

    log "sudo zfs create ${pool}/data -o mountpoint=${mountpoint}"
    sudo zfs create "${pool}/data" -o mountpoint="${mountpoint}"
  fi
done
