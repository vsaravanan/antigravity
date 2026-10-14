#!/bin/bash
# k8master-build-api.sh
# Runs entirely on k8master (invoked via: bash k8master-build-api.sh <image>)
# The repo is already synced by the host script before this runs.

set -exuo pipefail

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

logfile=$(get_caller_script)
start_log_file $logfile

check_status

mylog "check out source code from $project_path"
cd "$project_path"

checkout
mytag="$(git_tag)"
myimage="${module}:${mytag}"
latestimage="${module}:latest"

mylog "Build jar with Maven"
cd $project_path
mvn clean package

mylog "Build image with Buildah"
cd $project_path
mylog "🚀 buildah building latest image ..."
# buildah bud -t hello-api:latest -f deploy/Dockerfile .
buildah bud -t "${latestimage}" -f deploy/Dockerfile .

mylog "Record current git commit as the deployment tag"
echo "$mytag" | tee "$project_path/.current_tag"

mylog "buildah push image to registry "
#  buildah push --tls-verify=false hello-api:latest docker://k8master:5000/hello-api:latest
#  docker prefix is required

buildah push --tls-verify=false \
    ${latestimage} "docker://${registry_url}/${latestimage}"

mylog "tag   to ${myimage}"
buildah tag  ${latestimage} "${myimage}"

# required only on first time
kubectl scale deployment $module --replicas=0 || true

mylog "delete deployment $module"
kubectl delete deployment $module --ignore-not-found
#kubectl delete service $module-svc --ignore-not-found

mylog "Apply $module manifest"
kubectl apply -f "$deploy_path/$module.yaml"

mylog "wait for deployment"
kubectl wait --for=create deployment/$module --timeout=30s


## required only on first time
#kubectl scale deployment $module --replicas=1

# Restart pods to pull the latest image
# kubectl rollout restart deployment/$module

mylog "Wait for rollout to finish"
# kubectl rollout status deployment/hello-api
kubectl rollout status deployment/$module

check_status

mylog "check status of Evicted and Error"
kubectl get all -A | grep -E "Evicted|Error" || true

log_info "build complete on ${HOST}. Image: $myimage"

log_time



#log_info "Deleting pod for $module"
## required only on first time
#kubectl delete pod -l app=$module || true
#
#mylog "Roll out latest API image"
##  kubectl set image deployment/hello-api hello-api=k8master:5000/hello-api:latest
##  docker prefix is not required
#
#if ! kubectl set image deployment/$module $module="$registry_url/${myimage}"; then
#    kubectl create deployment "$module" --image="$registry_url/${myimage}"
#fi