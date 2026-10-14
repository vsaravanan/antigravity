#!/bin/bash
# common.sh
# Logging helpers for the host-side scripts (the ones you run locally,
# which then ssh into k8master). Remote logging lives in
# remote/k8master-common.sh, since that's a separate file that runs
# entirely on k8master.


source "$remote_dir/environment.sh"
start_time=$(date +%s)

fail() { printf '\n\033[1;31mFAILED: %s\033[0m\n' "$1" >&2; exit 1; }

log_info() {
  set +x
  printf '\n\033[1;36m==> %s\033[0m\n' " $1"
  set -x
}

log_warn() {
    echo "[WARN]  $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

get_caller_script() {
    # BASH_SOURCE[1] is the script that sourced this one
    local caller="${BASH_SOURCE[1]}"
    echo "$(basename "$caller" .sh)"
}


mylog() {
    set +x
    echo ""
    echo "========================================"
    printf '\n\033[1;36m==> %s\033[0m\n' "$1"
    echo "========================================"
    set -x
}


log_time() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    log_info "✅ Done! Total time: ${minutes}m ${seconds}s"

}

start_log_file() {

  mkdir -p /data/logs/$module/
  logfile=/data/logs/$module/$module-$1-$(date +%Y%m%d-%H%M%S).log
  exec > >(tee -a "$logfile") 2>&1
  mylog "Logfile: $logfile"

}


image_exists() {
    buildah inspect "$1" >/dev/null 2>&1
}

renameWithTimestamp() {
    local created=$(buildah inspect -f '{{.Docker.Created}}' "$1" )
    local timestamp=$(date -d "$created" +%Y%m%d%H%M%S 2>/dev/null || echo "unknown")
    echo $module:$timestamp
}

checkout() {
    mylog "checkout"
    cd "$project_path"
    git reset --hard
    git fetch
    git checkout
    git pull
    chmod +x  *.sh deploy/*.sh || true    
}

check_status() {

    mylog "check status of registry and hello"
    kubectl get all | grep -E "hello-api|hello-ui|registry" || true

    mylog "docker images"
    buildah images

}

git_tag() {
    cd "$project_path"

    local tag
    local tag2
    tag="$(git rev-parse --short HEAD)"
    tag2="$(git log -1 --pretty=%s | tr -d '[:space:]' | cut -c1-10)"
    tag2=$(clean_string "$tag2")
    echo "$tag-$tag2"
}


clean_string() {
    local input="$1"
    echo "$input" | sed 's/[^a-zA-Z0-9._-]/-/g'
}


cleanup_images() {
    local repo="$1"

    buildah images --format "{{.Name}} {{.Tag}}" |
    grep "${repo}" |
    while read -r name tag; do
        if [ "$tag" != "latest" ]; then
            echo "Deleting ${name}:${tag}"
            buildah rmi "${name}:${tag}"
        fi
    done
}
