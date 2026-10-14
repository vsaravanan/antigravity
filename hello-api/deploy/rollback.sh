#!/bin/bash
# k8master-rollback-ui.sh
# Runs entirely on k8master (invoked via: bash k8master-rollback-ui.sh)

set -exuo pipefail

# If no parameters, restart all
if [ $# -eq 0 ]; then
    echo "which tag to rolback "
    exit 0
fi

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

tag2=$(clean_string "$1")

myimage="${module}:${tag2}"

logfile=$(get_caller_script)
start_log_file $logfile

if image_exists "$myimage"; then
    log_info "image $myimage found "
else
    mylog "image $myimage not found in $registry_url"
    exit 0
fi

kubectl scale deployment $module --replicas=0

log_info "Deleting pod for $module"
kubectl delete pod -l app=$module || true

mylog "Roll out latest image"
# kubectl set image deployment/hello-ui hello-ui=k8master:5000/hello-ui:latest
kubectl set image deployment/$module $module="$registry_url/${myimage}"

kubectl scale deployment $module --replicas=1

mylog "Wait for rollout to finish"
# kubectl rollout status deployment/hello-ui
kubectl rollout status deployment/$module

log_info "rollback complete on k8master."
