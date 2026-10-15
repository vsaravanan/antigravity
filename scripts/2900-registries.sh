# in master
root@k8master:/etc/containers# cat registries.conf
[[registry]]
location = "k8master:5000"
insecure = true



Error: trying to reuse blob 
sha256:74d97c428c51a828f9051a7a40a53ff1fc99e54fc30323ce36760701b0b7f711 
at destination: pinging container registry k8master:5000: 
Get "https://k8master:5000/v2/": dial tcp 192.168.100.10:5000: 
connect: connection refused


kubectl apply -f /data/antigravity/hello-api/deploy/registry.yaml

Error: trying to reuse blob sha256:74d97c428c51a828f9051a7a40a53ff1fc99e54fc30323ce36760701b0b7f711
 at destination: pinging container registry k8master:5000:
  Get "https://k8master:5000/v2/": http: server 
  gave HTTP response to HTTPS client

buildah push --tls-verify=false hello-api:latest docker://k8master:5000/hello-api:latest

Linux: Edit /etc/docker/daemon.json:

{
  "insecure-registries": ["k8master:5000"]
}

sudo systemctl restart docker