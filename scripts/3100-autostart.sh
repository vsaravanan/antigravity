#!/bin/bash
# 3100-autostart.sh

# Auto start on host boot
lxc config set k8master   boot.autostart true
lxc config set k8worker1  boot.autostart true

# Higher number starts first (default 0)
lxc config set k8master   boot.autostart.priority 100
lxc config set k8worker1  boot.autostart.priority 50

# Seconds to wait after this container starts before starting the next one
lxc config set k8master   boot.autostart.delay 30