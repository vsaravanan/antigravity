#!/bin/bash
# 2800-create-users.sh

#   k exec -i keycloak-0 -n keycloak -- sh -c 'cat > /opt/keycloak/bin/2800-create-users.sh' < ./2800-create-users.sh
#   k exec -it -n keycloak pod/keycloak-0 -- bash
#  cd /opt/keycloak/bin            
#  bash ./2800-create-users.sh    

K=/opt/keycloak/bin/kcadm.sh
R=matrix-test

# log in as the master admin (change the credentials to yours)
$K config credentials --server http://localhost:8080/auth --realm master --user admin --password admin123

# realm
$K create realms -s realm=$R -s enabled=true

# roles
$K create roles -r $R -s name=viewer
$K create roles -r $R -s name=editor

# users, each with a password
for u in alice bob carol; do
  $K create users -r $R -s username=$u -s enabled=true
  $K set-password -r $R --username $u --new-password 'Test1234!'
done

# direct roles (alice gets none)
$K add-roles -r $R --uusername bob   --rolename viewer
$K add-roles -r $R --uusername carol --rolename editor