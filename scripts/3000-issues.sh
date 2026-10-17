 
pod/hello-api-6b4b6855f5-mzcqm         0/1     ImagePullBackOff 
pod/redis-5f567588fc-ds229             0/1     Pending

my kubernetes system in lxd in ubuntu 26 is very slow now.
remedy ?  
shall I restart
lxc start k8master k8worker1



root@k8master:~# free -h
               total        used        free      shared  buff/cache   available
Mem:           8.0Gi       1.7Gi       5.7Gi        13Mi       651Mi       6.3Gi
Swap:             0B          0B          0B


root@k8master:~# top -bn1 | head -15
top - 07:04:59 up 2 min,  1 user,  load average: 15.24, 11.84, 8.26
Tasks:  57 total,   1 running,  56 sleeping,   0 stopped,   0 zombie
%Cpu(s): 15.2 us, 41.3 sy,  0.0 ni, 13.0 id,  8.7 wa,  0.0 hi, 21.7 si,  0.0 st
MiB Mem :   8192.0 total,   6075.7 free,   1476.7 used,    652.9 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   6715.3 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    910 root      20   0   11.2g  85216  34812 S  26.7   1.0   0:30.54 etcd
    942 root      20   0 1401284 103224  35932 S  26.7   1.2   0:14.33 kube-co+
    949 root      20   0 1685700 426212  48908 S  20.0   5.1   0:56.78 kube-ap+
    654 root      20   0 2349352  72056  32368 S  13.3   0.9   0:22.38 kubelet
   1538 root      20   0 1533096 156692  53480 S  13.3   1.9   0:33.62 cilium-+
   2433 root      20   0   11696   4680   2576 R  13.3   0.1   0:00.09 top
    951 root      20   0 1375300  41884  21848 S   6.7   0.5   0:05.41 kube-sc+
   1148 root      20   0 1268276  10748   5276 S   6.7   0.1   0:01.97 contain+


High CPU usage (only 13% idle) with load average of 15.24. The main culprits are:

etcd: 26.7% CPU - database operations bottleneck
kube-proxy: 26.7% CPU - network proxy issues
kube-apiserver: 20% CPU - API server overloaded
kubelet: 13.3% CPU - node agent struggling
The high CPU and load average indicate the system is overwhelmed, likely due to:

Too many pod restarts (ImagePullBackOff loops)
Cilium CNI issues (13.3% CPU)
Kubernetes control plane components struggling   

======================================================


viswar@k8s:~$ kubectl get pv -o wide
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS     VOLUMEATTRIBUTESCLASS   REASON   AGE   VOLUMEMODE
keycloak-pv   5Gi        RWO            Retain           Bound    keycloak/keycloak-pvc   keycloak-local   <unset>                          29d   Filesystem
redis-data    10Gi       RWO            Retain           Bound    redis/redis-data                         <unset>                          41h   Filesystem



viswar@k8s:~$ kubectl get pvc -A
NAMESPACE   NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS     VOLUMEATTRIBUTESCLASS   AGE
keycloak    keycloak-pvc   Bound    keycloak-pv   5Gi        RWO            keycloak-local   <unset>                 29d
redis       redis-data     Bound    redis-data    10Gi       RWO                             <unset>                 41h



viswar@k8s:~$ kubectl describe pod redis-5f567588fc-ds229 -n redis
Name:             redis-5f567588fc-ds229
Namespace:        redis
Priority:         0
Service Account:  default
Node:             <none>
Labels:           app=redis
                  pod-template-hash=5f567588fc
Annotations:      <none>
Status:           Pending
IP:
IPs:              <none>
Controlled By:    ReplicaSet/redis-5f567588fc
Containers:
  redis:
    Image:      redis:8-alpine
    Port:       6379/TCP
    Host Port:  0/TCP
    Args:
      --appendonly
      yes
    Limits:
      cpu:     500m
      memory:  512Mi
    Requests:
      cpu:        100m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /data from data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-dqzbf (ro)
Conditions:
  Type           Status
  PodScheduled   False
Volumes:
  data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  redis-data
    ReadOnly:   false
  kube-api-access-dqzbf:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason            Age                    From               Message
  ----     ------            ----                   ----               -------
  Warning  FailedScheduling  66m (x3 over 73m)      default-scheduler  0/2 nodes are available: 1 node(s) didn't match PersistentVolume's node affinity, 1 node(s) had untolerated taint(s). no new claims to deallocate, preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  60m (x4 over 60m)      default-scheduler  0/2 nodes are available: 1 node(s) didn't match PersistentVolume's node affinity, 1 node(s) had untolerated taint(s). no new claims to deallocate, preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  60m                    default-scheduler  0/2 nodes are available: 1 node(s) didn't match PersistentVolume's node affinity, 1 node(s) had untolerated taint(s). no new claims to deallocate, preemption: 0/2 nodes are available: 2 Preemption is not helpful for scheduling.
  Warning  FailedScheduling  57m (x4 over 60m)      default-scheduler  0/2 nodes are available: 1 node(s) didn't match PersistentVolume's node affinity, 1 node(s) had untolerated 


viswar@k8s:~$ kubectl get pods
NAME                         READY   STATUS             RESTARTS        AGE
hello-api-6b4b6855f5-dhsfh   0/1     ImagePullBackOff   2 (5h32m ago)   16h
hello-api-6b4b6855f5-mzcqm   0/1     ImagePullBackOff   2 (5h32m ago)   16h
registry-7b486498d5-rl47b    1/1     Running            6 (177m ago)    2d16h



viswar@k8s:~$ kubectl describe pod -l app=hello-api | grep -A 10 Events
Events:
  Type     Reason   Age                    From     Message
  ----     ------   ----                   ----     -------
  Normal   Pulling  5m12s (x38 over 176m)  kubelet  spec.containers{hello-api}: Pulling image "k8master:5000/hello-api:latest"
  Warning  Failed   5m7s (x37 over 176m)   kubelet  spec.containers{hello-api}: Failed to pull image "k8master:5000/hello-api:latest": rpc error: code = NotFound desc = failed to pull and unpack image "k8master:5000/hello-api:latest": failed to resolve image: k8master:5000/hello-api:latest: not found
  Normal   BackOff  32s (x474 over 176m)   kubelet  spec.containers{hello-api}: Back-off pulling image "k8master:5000/hello-api:latest"
  Warning  Failed   32s (x474 over 176m)   kubelet  spec.containers{hello-api}: Error: ImagePullBackOff


Name:             hello-api-6b4b6855f5-mzcqm
Namespace:        default
--
Events:
  Type     Reason   Age                    From     Message
  ----     ------   ----                   ----     -------
  Normal   Pulling  5m13s (x38 over 176m)  kubelet  spec.containers{hello-api}: Pulling image "k8master:5000/hello-api:latest"
  Warning  Failed   5m7s (x37 over 176m)   kubelet  spec.containers{hello-api}: Failed to pull image "k8master:5000/hello-api:latest": rpc error: code = NotFound desc = failed to pull and unpack image "k8master:5000/hello-api:latest": failed to resolve image: k8master:5000/hello-api:latest: not found
  Normal   BackOff  32s (x471 over 176m)   kubelet  spec.containers{hello-api}: Back-off pulling image "k8master:5000/hello-api:latest"
  Warning  Failed   32s (x471 over 176m)   kubelet  spec.containers{hello-api}: Error: ImagePullBackOff

viswar@k8s:~$ kubectl get deployment hello-api -o jsonpath='{.spec.template.spec.containers[0].image}'
k8master:5000/hello-api:latest



viswar@k8s:~$ lxc exec k8worker1 -- bash -lc 'curl -v --connect-timeout 5 http://k8master:5000/v2/'
* Host k8master:5000 was resolved.
* IPv6: (none)
* IPv4: 192.168.100.10
*   Trying 192.168.100.10:5000...
* Established connection to k8master (192.168.100.10 port 5000) from 192.168.100.11 port 50280
* using HTTP/1.x
> GET /v2/ HTTP/1.1
> Host: k8master:5000
> User-Agent: curl/8.18.0
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK


viswar@k8s:~$ kubectl -n redis get pvc,pv
NAME                               STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/redis-data   Bound    redis-data   10Gi       RWO                           <unset>                 41h

NAME                           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS     VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/keycloak-pv   5Gi        RWO            Retain           Bound    keycloak/keycloak-pvc   keycloak-local   <unset>                          30d
persistentvolume/redis-data    10Gi       RWO            Retain           Bound    redis/redis-data                         <unset>                          41h



kubectl delete deployment redis   -n redis
kubectl delete service redis      -n redis
kubectl delete pod redis-5f567588fc-ds229   -n redis
kubectl delete replicaset redis-5f567588fc  -n redis

kubectl scale deployment hello-api --replicas=1


======================================================


default       pod/hello-api-6b4b6855f5-2bk5f         0/1     CrashLoopBackOff   16 (2m7s ago)    82m
default       service/hello-api-svc                        NodePort       10.109.167.208   <none>            80:30080/TCP                    82m
default       deployment.apps/hello-api         0/1     1            0           82m
default       replicaset.apps/hello-api-6b4b6855f5         1         1         0       82m



viswar@k8s:/data/antigravity/hello-api/deploy$ kubectl describe pod -l app=hello-api | grep -A 10 Events
Events:
  Type     Reason   Age                   From     Message
  ----     ------   ----                  ----     -------
  Normal   Pulled   51m                   kubelet  spec.containers{hello-api}: Successfully pulled image "k8master:5000/hello-api:latest" in 893ms (2.135s including waiting). Image size: 133085576 bytes.
  Normal   Pulled   26m                   kubelet  spec.containers{hello-api}: Successfully pulled image "k8master:5000/hello-api:latest" in 736ms (1.152s including waiting). Image size: 133085576 bytes.
  Warning  BackOff  4m42s (x43 over 80m)  kubelet  spec.containers{hello-api}: Back-off restarting failed container hello-api in pod hello-api-6b4b6855f5-2bk5f_default(ef5d0c4c-6b96-45cf-9e4b-2dc06e9673a6)
  Normal   Pulling  2m51s (x17 over 82m)  kubelet  spec.containers{hello-api}: Pulling image "k8master:5000/hello-api:latest"

viswar@k8s:/data/antigravity/hello-api/deploy$ podman images
REPOSITORY                         TAG               IMAGE ID      CREATED            SIZE
localhost/hello-api                83bb99e-analysis  c67ca31b9254  About an hour ago  289 MB
localhost/hello-api                latest            c67ca31b9254  About an hour ago  289 MB


viswar@k8s:/data/antigravity/hello-api/deploy$ lxc exec k8worker1 -- bash -lc 'curl -v --connect-timeout 5 http://k8master:5000/v2/'
* Host k8master:5000 was resolved.
* IPv6: (none)
* IPv4: 192.168.100.10
*   Trying 192.168.100.10:5000...
* Established connection to k8master (192.168.100.10 port 5000) from 192.168.100.11 port 39958
* using HTTP/1.x
> GET /v2/ HTTP/1.1
> Host: k8master:5000
> User-Agent: curl/8.18.0
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK


Previous: ImagePullBackOff — image unavailable.
Current: CrashLoopBackOff — the container starts and then exits repeatedly.

======================================================


kubectl logs pod/hello-api-6b4b6855f5-2bk5f

Caused by: org.springframework.beans.factory.UnsatisfiedDependencyException: Error creating bean with name 'redisService' defined in URL [jar:nested:/app/hello-api.jar/!BOOT-INF/classes/!/com/saravanjs/hello/service/RedisService.class]:

Caused by: org.redisson.client.RedisConnectionException: java.net.UnknownHostException: Failed to resolve 'redis.redis.svc.cluster.local' [A(1)]

======================================================



kubectl delete ns redis --ignore-not-found
kubectl delete pv redis-data --ignore-not-found
namespace "redis" deleted
persistentvolume "redis-data" deleted

======================================================



# 1. Clean up the earlier attempt
kubectl delete ns redis --ignore-not-found
kubectl delete pv redis-data --ignore-not-found

# 2. Apply
kubectl apply -f redis.yaml

# 3. Check
kubectl -n redis get pod,pvc,pv,svc
kubectl -n redis exec deploy/redis -- redis-cli ping


viswar@k8s:/data/antigravity/redis$ kubectl -n redis get pod,pvc,pv,svc
NAME                         READY   STATUS    RESTARTS   AGE
pod/redis-79d84fcd75-sdmb7   1/1     Running   0          46s

NAME                               STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/redis-data   Bound    redis-data   10Gi       RWO                           <unset>                 46s

NAME                           CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS     VOLUMEATTRIBUTESCLASS   REASON   AGE
persistentvolume/keycloak-pv   5Gi        RWO            Retain           Bound    keycloak/keycloak-pvc   keycloak-local   <unset>                          30d
persistentvolume/redis-data    10Gi       RWO            Retain           Bound    redis/redis-data                         <unset>                          46s

NAME                TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/redis-svc   NodePort   10.107.123.176   <none>        6379:30079/TCP   46s


viswar@k8s:/data/antigravity/redis$ kubectl -n redis describe pod -l app=redis | sed -n '/Events:/,$p'
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  4m3s   default-scheduler  Successfully assigned redis/redis-79d84fcd75-sdmb7 to k8master
  Normal  Pulling    4m1s   kubelet            spec.containers{redis}: Pulling image "redis:8-alpine"
  Normal  Pulled     3m30s  kubelet            spec.containers{redis}: Successfully pulled image "redis:8-alpine" in 30.633s (30.633s including waiting). Image size: 39122324 bytes.
  Normal  Created    3m30s  kubelet            spec.containers{redis}: Container created
  Normal  Started    3m29s  kubelet            spec.containers{redis}: Container started



viswar@k8s:/data/antigravity/redis$ kubectl -n redis exec deploy/redis -- redis-cli ping
PONG

kubectl exec -n redis deployment/redis -- redis-cli CONFIG GET appendonly
appendonly
yes

kubectl exec -n redis deployment/redis -- redis-cli INFO persistence
# Persistence
loading:0


kubectl scale deployment hello-api --replicas=2


viswar@k8s:/data/antigravity/redis$ kubectl get pods -l app=hello-api -w
NAME                         READY   STATUS    RESTARTS        AGE
hello-api-6b4b6855f5-5cdd4   1/1     Running   2 (20s ago)     96s
hello-api-6b4b6855f5-thslv   0/1     Error     4 (4m46s ago)   8m36s


viswar@k8s:/data/antigravity/hello-api/deploy$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
NAME        TAINTS
k8master    [map[effect:NoSchedule key:node-role.kubernetes.io/control-plane]]
k8worker1   <none>
viswar@k8s:/data/antigravity/hello-api/deploy$ kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
node/k8master untainted
error: taint "node-role.kubernetes.io/control-plane:NoSchedule" not found
viswar@k8s:/data/antigravity/hello-api/deploy$ kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
NAME        TAINTS
k8master    <none>
k8worker1   <none>


