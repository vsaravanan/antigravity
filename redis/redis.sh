kubectl create namespace redis

mkdir -p /data/redis
cd /data/redis

kubectl apply -f redis.yaml
kubectl apply -f redis-service.yaml

kubectl run redis-test \
    --rm -it \
    --image=redis:8-alpine \
    -n redis \
    -- sh

inside the pod

redis-cli -h redis
you should get
redis:6379

redis:6379> SET name Saravanan
OK
redis:6379> GET name
"Saravanan"


INSIDE ANY POD :

root@k8master:/data/java/Hello/redis# kubectl run dns-test   --image=busybox:1.36   --restart=Never   -it --rm -- sh
If you dont see a command prompt, try pressing enter.
/ #
/ #
/ #  nslookup redis.redis.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53


Name:   redis.redis.svc.cluster.local
Address: 10.100.174.208

lxc config device add k8master redis proxy listen=tcp:0.0.0.0:6379 connect=tcp:192.168.100.10:6379

