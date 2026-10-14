set -exuo pipefail

# If no parameters, restart all
if [ $# -eq 0 ]; then
    echo "which app need to be restarted "
    exit 0
fi

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

module=${1:-hello-api}
kubectl delete deployment $module || true
kubectl delete rs   -l app=$module || true
kubectl delete pods -l app=$module || true

buildah push --tls-verify=false     $module:latest "docker://k8master:5000/$module:latest"

kubectl apply -f "$deploy_path/$module.yaml"