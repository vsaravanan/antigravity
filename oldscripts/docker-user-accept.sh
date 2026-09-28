#!/bin/bash
# docker-user-accept.sh



# cat /etc/rc.local
# #!/bin/bash

# bash /data/k8s-lxd-lab/scripts/only-once-after-reboot.sh

# exit 0


# cat /data/scripts/only-once-after-reboot.sh

# echo "pm2 resurrecting.... "
# /root/.local/share/pnpm/bin/pm2 resurrect && /root/.local/share/pnpm/bin/pm2 start all

# sudo chmod +x /etc/rc.local
# sudo systemctl enable rc-local
# sudo systemctl start rc-local
# sudo systemctl status rc-local


set -euo pipefail

BRIDGE="k8sbr0"
CHAIN="DOCKER-USER"

echo "==> Waiting for Docker..."

until systemctl is-active --quiet docker; do
    sleep 2
done

echo "==> Docker is running."



echo "==> Applying k8sbr0 forwarding rules..."

# Add rule only if it doesn't already exist
if ! iptables -C "$CHAIN" -i "$BRIDGE" -j ACCEPT 2>/dev/null; then
    iptables -I "$CHAIN" -i "$BRIDGE" -j ACCEPT
    echo "    Added: -i $BRIDGE -j ACCEPT"
else
    echo "    Already exists: -i $BRIDGE -j ACCEPT"
fi

if ! iptables -C "$CHAIN" -o "$BRIDGE" -j ACCEPT 2>/dev/null; then
    iptables -I "$CHAIN" -o "$BRIDGE" -j ACCEPT
    echo "    Added: -o $BRIDGE -j ACCEPT"
else
    echo "    Already exists: -o $BRIDGE -j ACCEPT"
fi

echo
echo "==> Current DOCKER-USER rules:"
iptables -L "$CHAIN" -n -v

echo
echo "==> k8sbr0 Docker forwarding fix applied."


# it should run only one after every reboot
#
# root@k8s:~# cat /root/.pm2/logs/docker-accept-out.log
# ==> Waiting for Docker...
# ==> Docker is running.
# ==> Applying k8sbr0 forwarding rules...
#     Already exists: -i k8sbr0 -j ACCEPT
#     Already exists: -o k8sbr0 -j ACCEPT

# ==> Current DOCKER-USER rules:
# Chain DOCKER-USER (1 references)
#  pkts bytes target     prot opt in     out     source               destination
#  137K   41M ACCEPT     all  --  *      k8sbr0  0.0.0.0/0            0.0.0.0/0
#   171 38930 ACCEPT     all  --  k8sbr0 *       0.0.0.0/0            0.0.0.0/0

# ==> k8sbr0 Docker forwarding fix applied.

