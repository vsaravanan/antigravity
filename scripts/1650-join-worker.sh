
#!/usr/bin/env bash
# 1650-join-worker.sh 
set -exuo pipefail

chmod +x ./join-command.sh
cat ./join-command.sh
kubeadm join 192.168.100.10:6443 --token 9y4iet.bfkodwh5chezupgf --discovery-token-ca-cert-hash sha256:c07461df59266f0ef99b7b559c0bf5f8d5b91f11ef9672f2856e752d25f84b44
$(cat ./join-command.sh) --ignore-preflight-errors=Swap,SystemVerification,Mem


# IN MASTER 

kubectl -n kube-system rollout status daemonset/cilium --timeout=180s


lxc snapshot k8master after-1650-join-worker
lxc snapshot k8worker1 after-1650-join-worker