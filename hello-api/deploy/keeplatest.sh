
set -exuo pipefail

# If no parameters, restart all
if [ $# -eq 0 ]; then
    echo "which app to be cleaned up "
    exit 0
fi

module=$1

cleanup_images() {
    local repo="$1"

    podman images --format "{{.Name}} {{.Tag}}" |
    grep "${repo}" |
    while read -r name tag; do
        if [ "$tag" != "latest" ]; then
            echo "Deleting ${name}:${tag}"
            podman rmi "${name}:${tag}"
        fi
    done
}

podman images
cleanup_images $module


podman images