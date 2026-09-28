#!/usr/bin/env bash
# 2175-install-pulumi-host.sh — run on the HOST, after 2160-install-docker-host.sh
# and `docker compose up -d` (docker-compose.yml).
set -euo pipefail

log()  { echo -e "\033[1;32m[INFO]\033[0m  $*"; }

MINIO_ENDPOINT="127.0.0.1:9000"
MINIO_ROOT_USER="pulumiadmin"
MINIO_ROOT_PASSWORD="pulumipwd"   # must match docker-compose.yml
MINIO_BUCKET="pulumi-state"

# ---------------------------------------------------------------------------
log "==> Waiting for MinIO (docker compose) to be reachable"
until curl -sf http://127.0.0.1:9000/minio/health/live >/dev/null; do sleep 1; done

log "==> Installing Pulumi CLI"
curl -fsSL https://get.pulumi.com | sh
echo 'export PATH=$PATH:$HOME/.pulumi/bin' >> ~/.bashrc
export PATH=$PATH:$HOME/.pulumi/bin

# ---------------------------------------------------------------------------
log "==> Configuring Pulumi to use MinIO as its state backend (S3-compatible)"
export AWS_ACCESS_KEY_ID="${MINIO_ROOT_USER}"
export AWS_SECRET_ACCESS_KEY="${MINIO_ROOT_PASSWORD}"
echo "export AWS_ACCESS_KEY_ID=${MINIO_ROOT_USER}" >> ~/.bashrc
echo "export AWS_SECRET_ACCESS_KEY=${MINIO_ROOT_PASSWORD}" >> ~/.bashrc

# Pulumi requires a passphrase to encrypt secrets in self-managed backends.
# Change this — this is a placeholder for the lab.
export PULUMI_CONFIG_PASSPHRASE="darkroom"
echo 'export PULUMI_CONFIG_PASSPHRASE=darkroom' >> ~/.bashrc

pulumi login "s3://${MINIO_BUCKET}?endpoint=${MINIO_ENDPOINT}&s3ForcePathStyle=true&disableSSL=true"

log "==> Done. Verify with: pulumi whoami --verbose"
log "    Next: pulumi new kubernetes-python (or your language of choice) to start a stack"