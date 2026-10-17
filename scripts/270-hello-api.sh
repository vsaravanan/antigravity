#!/usr/bin/env bash
# 270-hello-api.sh

set -euo pipefail

VBOXMANAGE='/cygdrive/c/Programs/Oracle/VirtualBox/VBoxManage.exe'
VDI_DIR='D:/vm/k8s'

file=hello-api

"$VBOXMANAGE" createmedium \
    disk --filename "$VDI_DIR/$file.vdi" --size 10240 \
    --format VDI --variant Standard

"$VBOXMANAGE" storageattach k8s \
    --storagectl "SATA" --port 20 --device 0 \
    --type hdd --medium "$VDI_DIR/$file.vdi" \
    --nonrotational on --discard on