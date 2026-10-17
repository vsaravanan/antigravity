#!/bin/bash
# environment.sh (frontend / hello-ui)
# Sourced by every host-side script in this deploy/ folder.
# This file lives inside the hello-ui repo, so it's identical on the
# host and on k8master once git pull has synced them.

HOST="k8master"
git_url="https://github.com/vsaravanan/hello-ui.git"
module=hello-ui
service="$module-svc"
root_path="/data/antigravity"
project_path="$root_path/$module"
deploy_path="$project_path/deploy"
registry_url="k8master:5000"
myimage_base="$module-base:latest"
myimage="$module:latest"


