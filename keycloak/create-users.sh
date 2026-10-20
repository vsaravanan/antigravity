#!/bin/bash
# create-users.sh

#   k exec -i keycloak-0 -n keycloak -- sh -c 'cat > /opt/keycloak/bin/create-users.sh' < ./create-users.sh
#   k exec -it -n keycloak pod/keycloak-0 -- bash
#  cd /opt/keycloak/bin            
#  bash ./create-users.sh    

K=/opt/keycloak/bin/kcadm.sh
R=matrix-test

# log in as the master admin (change the credentials to yours)
$K config credentials --server http://localhost:8080/auth --realm master --user admin --password admin123
$K create realms -f /tmp/realm-export.json

