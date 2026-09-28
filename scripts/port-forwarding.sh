#!/bin/bash
# port-forwarding.sh


kubectl patch svc hubble-ui -n kube-system \
  -p '{"spec":{"type":"NodePort","ports":[{"port":80,"targetPort":8081,"nodePort":30081}]}}'


k8s:~$ curl -v k8master:30081 
working

viswar@k8s:~$ echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-k8s-forwarding.conf
sudo sysctl --system

sudo nft add table ip k8s-nat
sudo nft 'add chain ip k8s-nat prerouting { type nat hook prerouting priority -100; }'
sudo nft add rule ip k8s-nat prerouting ip daddr 192.168.50.84 tcp dport 30000-32767 dnat to 192.168.100.10
sudo nft add rule ip k8s-nat prerouting ip daddr 192.168.50.84 udp dport 30000-32767 dnat to 192.168.100.10
sudo nft add table ip k8s-forward
sudo nft 'add chain ip k8s-forward forward { type filter hook forward priority 0; policy accept; }'
sudo nft list ruleset

sudo tcpdump -ni enp0s3 tcp port 30081
sudo tcpdump -ni k8sbr0 tcp port 30081
http://192.168.50.84:30081

You should see traffic on both interfaces.


viswar@k8s:~$ sudo nft list table ip k8s-nat
[sudo: authenticate] Password:
table ip k8s-nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                ip daddr 192.168.50.84 tcp dport 30000-32767 dnat to 192.168.100.10
                ip daddr 192.168.50.84 udp dport 30000-32767 dnat to 192.168.100.10
        }
}


7. Make the configuration permanent
The nft add commands above are not sufficient by themselves because the rules may disappear after reboot.

sudo apt update
sudo apt install -y nftables


viswar@k8s:~$ sudo vi /etc/nftables.conf
viswar@k8s:~$
viswar@k8s:~$
viswar@k8s:~$
viswar@k8s:~$ cat  /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
        chain input {
                type filter hook input priority filter;
        }
        chain forward {
                type filter hook forward priority filter;
        }
        chain output {
                type filter hook output priority filter;
        }
}




table ip k8s-nat {
    chain prerouting {
        type nat hook prerouting priority -100;

        ip daddr 192.168.50.84 tcp dport 30000-32767 dnat to 192.168.100.10
        ip daddr 192.168.50.84 udp dport 30000-32767 dnat to 192.168.100.10
    }
}

table ip k8s-forward {
    chain forward {
        type filter hook forward priority 0;
        policy accept;
    }
}



sudo systemctl enable nftables
sudo systemctl restart nftables

# verify
sudo nft list ruleset



VirtualBox
    Adapter 1 = Bridged
         │
         ▼
Linux VM
192.168.50.84
         │
         │ IP forwarding + nftables
         ▼
LXD managed NAT
k8sbr0
192.168.100.1/24
         │
         ├── k8master 192.168.100.10
         │       │
         │       └── Cilium NodePort
         │
         └── k8worker1 192.168.100.11



Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

PS C:\WINDOWS\system32> route add 192.168.100.0 mask 255.255.255.0 192.168.50.84
 OK!
PS C:\WINDOWS\system32>

# DELETE first
route delete 192.168.100.0

# TO MAKE IT PERSISTENT, run PowerShell as Administrator and execute:
route -p add 192.168.100.0 mask 255.255.255.0 192.168.50.84


PS C:\Users\Sarav> route print 192.168.100.0
===========================================================================
Interface List
 15...7c 10 c9 91 1c 54 ......Realtek PCIe GbE Family Controller
 23...10 5f ad 75 67 c9 ......Microsoft Wi-Fi Direct Virtual Adapter #5
 12...12 5f ad 75 67 c8 ......Microsoft Wi-Fi Direct Virtual Adapter #6
 30...10 5f ad 75 67 c8 ......Intel(R) Wi-Fi 6E AX210 160MHz
 11...00 50 56 c0 00 01 ......VMware Virtual Ethernet Adapter for VMnet1
 16...00 50 56 c0 00 08 ......VMware Virtual Ethernet Adapter for VMnet8
  4...10 5f ad 75 67 cc ......Bluetooth Device (Personal Area Network) #2
  1...........................Software Loopback Interface 1
===========================================================================

IPv4 Route Table
===========================================================================
Active Routes:
Network Destination        Netmask          Gateway       Interface  Metric
    192.168.100.0    255.255.255.0    192.168.50.84   192.168.50.127     26
===========================================================================
Persistent Routes:
  None

IPv6 Route Table
===========================================================================
Active Routes:
  None
Persistent Routes:
  None




viswar@k8s:~$ ip route get 192.168.100.240
192.168.100.240 dev k8sbr0 src 192.168.100.1 uid 1000
    cache
viswar@k8s:~$


viswar@k8s:~$ kubectl -n kube-system exec ds/cilium -- cilium service list
ID   Frontend                  Service Type   Backend
1    10.98.245.122:443/TCP     ClusterIP      1 => 192.168.100.10:4244/TCP (active)
2    10.98.132.55:80/TCP       ClusterIP      1 => 10.244.1.110:4245/TCP (active)
3    10.109.198.214:443/TCP    ClusterIP      1 => 10.244.1.120:8080/TCP (active)
4    0.0.0.0:30163/TCP         NodePort       1 => 10.244.1.93:8000/TCP (active)
6    0.0.0.0:32173/TCP         NodePort       1 => 10.244.1.93:8443/TCP (active)
8    10.110.221.180:80/TCP     ClusterIP      1 => 10.244.1.93:8000/TCP (active)
9    10.110.221.180:443/TCP    ClusterIP      1 => 10.244.1.93:8443/TCP (active)
10   192.168.100.240:80/TCP    LoadBalancer   1 => 10.244.1.93:8000/TCP (active)
11   192.168.100.240:443/TCP   LoadBalancer   1 => 10.244.1.93:8443/TCP (active)
12   0.0.0.0:30081/TCP         NodePort       1 => 10.244.1.63:8081/TCP (active)
14   10.108.133.231:80/TCP     ClusterIP      1 => 10.244.1.63:8081/TCP (active)
15   10.96.0.10:53/TCP         ClusterIP      1 => 10.244.0.104:53/TCP (active)
                                              2 => 10.244.0.106:53/TCP (active)
16   10.96.0.10:53/UDP         ClusterIP      1 => 10.244.0.104:53/UDP (active)
                                              2 => 10.244.0.106:53/UDP (active)
17   10.96.0.10:9153/TCP       ClusterIP      1 => 10.244.0.104:9153/TCP (active)
                                              2 => 10.244.0.106:9153/TCP (active)
18   10.96.0.1:443/TCP         ClusterIP      1 => 192.168.100.10:6443/TCP (active)
19   10.98.133.38:10254/TCP    ClusterIP      1 => 10.244.1.120:10254/TCP (active)
20   10.98.133.38:10255/TCP    ClusterIP      1 => 10.244.1.120:10255/TCP (active)
21   0.0.0.0:31241/TCP         NodePort       1 => 10.244.1.93:8445/TCP (active)
23   0.0.0.0:32422/TCP         NodePort       1 => 10.244.1.93:8002/TCP (active)
25   10.105.13.212:8002/TCP    ClusterIP      1 => 10.244.1.93:8002/TCP (active)
26   10.105.13.212:8445/TCP    ClusterIP      1 => 10.244.1.93:8445/TCP (active)
