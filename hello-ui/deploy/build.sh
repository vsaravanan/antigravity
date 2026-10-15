#!/bin/bash
# k8master-build-ui.sh
# Runs entirely on k8master (invoked via: bash k8master-build-ui.sh <image>)
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

mylog "Install dependencies with pnpm"
cd "$project_path"
pnpm self-update latest
pnpm install 

mylog "Build with pnpm"
cd "$project_path"
pnpm build

mylog "Build image with Buildah"
cd "$project_path"



if [ "${1:-}" = "base" ]; then
    mylog "🚀 podman building base image ..."
    #  podman bud -t hello-ui-base:latest -f deploy/Dockerfile.base:
    podman bud -t "$myimage_base" -f deploy/Dockerfile.base

    mylog " podman pushing base image to registry"
    podman push --tls-verify=false "$myimage_base" "docker://${registry_url}/${myimage_base}"
    # podman push --tls-verify=false hello-ui-base:latest docker://k8master:5000/hello-ui-base:latest
    mylog "✅ Base image built and pushed!"
fi

mylog "Record current git commit as the deployment tag"
echo "$mytag" | tee "$project_path/.current_tag"

mylog "🚀 podman building latest image ..."
# podman bud -t hello-ui:latest -f deploy/Dockerfile .
podman bud -t "${latestimage}" -f deploy/Dockerfile .


mylog "podman push image to registry "
# podman push --tls-verify=false hello-ui:latest docker://k8master:5000/hello-ui:latest
podman push --tls-verify=false \
    "${latestimage}" "docker://$registry_url/${latestimage}"

mylog "tag   to ${myimage}"
podman tag  ${latestimage} "${myimage}"

kubectl scale deployment $module --replicas=0 || true

mylog "delete deployment $module"
kubectl delete deployment $module --ignore-not-found

mylog "Apply $module manifest"
kubectl apply -f "$deploy_path/$module.yaml"

mylog "wait for deployment"
kubectl wait --for=create deployment/$module --timeout=30s

kubectl scale deployment $module --replicas=1

mylog "Wait for rollout to finish"
# kubectl rollout status deployment/hello-ui
kubectl rollout status deployment/$module


check_status

mylog "check status of Evicted and Error"
kubectl get all -A | grep -E "Evicted|Error" || true


log_info "build complete on ${HOST}. Image: $myimage"


log_time 




# log_info "Deleting pod for $module"
# kubectl delete pod -l app=$module || true

# mylog "Roll out latest UI image"
# # kubectl set image deployment/hello-ui hello-ui=k8master:5000/hello-ui:latest

# if ! kubectl set image deployment/$module $module="$registry_url/${myimage}"; then
#     kubectl create deployment "$module" --image="$registry_url/${myimage}"
# fi