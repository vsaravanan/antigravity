pulumi stack init dev
pulumi install
# export KUBECONFIG=~/.kube/config   # from 16-fetch-kubeconfig-host.sh — needed before 'up'
pulumi preview
pulumi up