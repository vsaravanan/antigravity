#!/bin/bash
# k8master-validate-api.sh
# Runs entirely on k8master (invoked via: bash k8master-validate-api.sh)

set -exuo pipefail

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"


mylog "Check $module pod status"
kubectl get pods -l app=$module

mylog "Wait for $module pod to be Ready"
kubectl wait --for=condition=Ready pod -l app=$module --timeout=60s

mylog "Curl $module health endpoint"
kubectl run curl-api-check --rm -i --restart=Never --image=curlimages/curl -- curl -sf http://$service:8080/actuator/health

log_info "validate-api complete on $HOST."
