#!/bin/bash
# k8master-validate-ui.sh
# Runs entirely on k8master (invoked via: bash k8master-validate-ui.sh)

set -euo pipefail

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"


mylog "Check $module pod status"
kubectl get pods -l app=$module

mylog "Wait for $module pod to be Ready"
kubectl wait --for=condition=Ready pod -l app=$module --timeout=60s

log_info "validate-ui complete on k8master."
