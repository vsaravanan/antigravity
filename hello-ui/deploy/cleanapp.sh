
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

#buildah images | grep "^localhost/${module}" | while read repo tag rest; do
#    buildah rmi "$repo:$tag" || true
#done

buildah images --format "{{.Name}}:{{.Tag}}" \
| grep "^localhost/$module" \
| xargs -r buildah rmi || true


kubectl scale deployment $module --replicas=0 || true

sleep 2

kubectl delete svc $service || true

kubectl delete deployment $module || true

kubectl delete rs   -l app=$module || true
kubectl delete pods -l app=$module || true
kubectl delete all  -l app=$module || true

kubectl get deploy,svc | grep -E "$module" || true

check_status


log_time