#!/usr/bin/env bash
# 00c-install-lxd.sh — run from the HOST

set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m  $*"; }


# ---------------------------------------------------------------------------
log "==> Installing ZFS + LXD"
sudo apt update
sudo apt install -y zfsutils-linux
if ! command -v lxd >/dev/null 2>&1; then
  sudo snap install lxd
fi