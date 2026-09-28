#!/usr/bin/env bash
# 2177-install-uv-host.sh — run on the HOST.
set -euo pipefail
curl -LsSf https://astral.sh/uv/install.sh | sh


echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
export PATH=$HOME/.local/bin:$PATH
uv --version
 