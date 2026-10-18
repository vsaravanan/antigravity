
set -exuo pipefail

# If no parameters, restart all
if [ $# -eq 0 ]; then
    echo "which app to be cleaned up "
    exit 0
fi

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

rm /data/logs/$module/* || true

logfile=$(get_caller_script)
start_log_file $logfile

mylog "check out source code from $project_path"
cd "$project_path"

checkout

check_status

module=$1
service="$module-svc"


#podman images | grep "^localhost/${module}" | while read repo tag rest; do
#    podman rmi "$repo:$tag" || true
#done

# check which containers reference it:
# podman ps -a --no-trunc

# podman image prune
# WARNING! This command removes all dangling images.

# podman images --format '{{.Repository}}:{{.Tag}}' \
#   | grep '^localhost/' \
#   | xargs -r podman rmi

podman images --format "{{.Repository}}:{{.Tag}}" \
| grep "^localhost/$module" \
| xargs -r podman rmi || true


kubectl -n $ns scale deployment $module --replicas=0 || true

sleep 2

kubectl -n $ns delete svc $service || true

kubectl -n $ns delete deployment $module || true

kubectl -n $ns delete rs   -l app=$module || true
kubectl -n $ns delete pods -l app=$module || true
kubectl -n $ns delete ingress $module || true
kubectl -n $ns delete pvc -l app=$module || true
kubectl -n $ns delete configmap -l app=$module || true
kubectl -n $ns delete secret -l app=$module || true

kubectl -n $ns delete all  -l app=$module || true
kubectl delete namespace $ns || true

kubectl get all,deploy,svc,configmap,secret,pvc -n $ns || true

check_status


log_time