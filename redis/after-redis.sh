 sudo apt install redis-tools



 kubectl get deploy hello-api -o yaml | grep -n -i -E 'redis|livenessProbe|readinessProbe|path:|port:'

kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup redis-svc.redis.svc.cluster.local
kubectl -n kube-system get pods -l k8s-app=kube-dns


NAME                       READY   STATUS    RESTARTS      AGE
coredns-589f44dc88-7zbhk   1/1     Running   39 (9h ago)   43d
coredns-589f44dc88-r22wg   1/1     Running   4 (9h ago)    2d4h


# 3. The actual exit reason, ignoring the Netty noise
kubectl describe pod -l app=hello-api | grep -A8 'Last State'
kubectl logs -l app=hello-api --previous | grep -v -E '^\s+at |UDP|exceptionCaught' | tail -30

kubectl rollout restart deploy hello-api

Test-NetConnection 192.168.50.84 -Port 30081

ComputerName     : 192.168.50.84
RemoteAddress    : 192.168.50.84
RemotePort       : 30081
InterfaceAlias   : Ethernet
SourceAddress    : 192.168.50.127
TcpTestSucceeded : True
