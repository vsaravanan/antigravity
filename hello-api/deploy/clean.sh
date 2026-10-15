
set -exuo pipefail

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

rm /data/logs/hello-api/* || true
rm /data/logs/hello-ui/* || true

logfile=$(get_caller_script)
start_log_file $logfile

mylog "check out source code from $project_path"
cd "$project_path"

checkout

check_status

kubectl scale deployment hello-api hello-ui registry --replicas=0 || true

kubectl delete svc hello-api-svc hello-ui-svc registry-svc || true

kubectl delete deployment hello-api hello-ui registry || true

kubectl delete rs   -l app=registry -l app=hello-api -l app=hello-ui || true
kubectl delete pods -l app=registry -l app=hello-api -l app=hello-ui || true
kubectl delete all  -l app=registry -l app=hello-api -l app=hello-ui || true

kubectl get deploy,svc | grep -E "registry|hello-api|hello-ui" || true

buildah rmi --all --force || true

check_status


log_time