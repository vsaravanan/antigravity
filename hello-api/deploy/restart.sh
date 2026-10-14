
set -exuo pipefail

remote_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$remote_dir/common.sh"

logfile=$(get_caller_script)
start_log_file $logfile

mylog "check out source code from $project_path"
cd "$project_path"

checkout

check_status



# If no parameters, restart all
if [ $# -eq 0 ]; then
    exit 0
fi


for service in "$@"; do
    if [ "$service" = "registry" ] || [ "$service" = "all"  ]; then

        # 1. Start Registry first (needed to pull images)
        mylog "📦 1. Starting Registry..."
        kubectl scale deployment registry --replicas=1
        kubectl rollout status deployment/registry --timeout=60s

        # 2. Wait for registry to be ready
        mylog "⏳ Waiting for registry to be ready..."
        kubectl wait --for=condition=available deployment/registry --timeout=60s

    elif [ "$service" = "hello-api" ] || [ "$service" = "all" ]; then
        # 3. Start hello-api (needs registry to pull image)
        mylog "📦 2. Starting hello-api..."
#        kubectl set image deployment/hello-api hello-api=k8master:5000/hello-api:latest
        kubectl scale deployment hello-api --replicas=1
        kubectl rollout status deployment/hello-api --timeout=60s

        # 4. Wait for hello-api to be ready
        mylog "⏳ Waiting for hello-api to be ready..."
        kubectl wait --for=condition=available deployment/hello-api --timeout=60s


    elif [ "$service" = "hello-ui" ] || [ "$service" = "all" ]; then


        # 5. Start hello-ui (needs hello-api to function)
        mylog "📦 3. Starting hello-ui..."
#        kubectl set image deployment/hello-ui hello-ui=k8master:5000/hello-ui:latest
        kubectl scale deployment hello-ui --replicas=1
        kubectl rollout status deployment/hello-ui --timeout=60s



    else
        echo "❌ Invalid: $service"
    fi
done


# 6. Final verification
mylog -e "\n📊 Final status:"
kubectl get pods -l app=registry || true
kubectl get pods -l app=hello-api || true
kubectl get pods -l app=hello-ui || true    


check_status

log_time



