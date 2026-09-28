viswar@k8s:/data/k8s-lxd-lab/main/scripts$ sudo usermod -aG docker viswar
[sudo: authenticate] Password:
viswar@k8s:/data/k8s-lxd-lab/main/scripts$ newgrp docker
viswar@k8s:/data/k8s-lxd-lab/main/scripts$ docker ps
CONTAINER ID IMAGE COMMAND CREATED STATUS PORTS NAMES


viswar@k8s:/data/k8s-lxd-lab/main/scripts$ docker compose up -d
[+] up 3/3
 ✔ Container mysql                   Started                                                                                                  2.2s
 ✔ Container minio                   Started                                                                                                  4.3s
 ✔ Container scripts-createbuckets-1 Started                 


docker stop mysql
docker start mysql
docker stop minio
docker start minio