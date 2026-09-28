pulumi state unprotect 'urn:pulumi:kong-learning-lab-dev::kong-learning-lab::kubernetes:core/v1:Namespace::kongNs'
pulumi state unprotect 'urn:pulumi:dev::kong-learning-lab::kubernetes:core/v1:Namespace::kongNs'
pulumi destroy
pulumi stack rm dev
cd ../kong-pulumi-example/
pulumi destroy
pulumi stack rm dev

clear; kga
ll

kubectl get ns | grep -E 'kong|keycloak'
kubectl delete ns kong kong-lab keycloak --wait=true

kubectl get crd -o name | grep -E 'konghq.com|gateway.networking.k8s.io' | xargs -r kubectl delete
kubectl get validatingadmissionpolicy,validatingadmissionpolicybinding -o name | grep -i gateway | xargs -r kubectl delete
kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration -o name | grep -i kong | xargs -r kubectl delete
kubectl get clusterrole,clusterrolebinding -o name | grep -i kong | xargs -r kubectl delete
kubectl get ingressclass -o name | grep -i kong | xargs -r kubectl delete
kubectl get pv | grep keycloak
kubectl delete pv keycloak-pv 2>/dev/null || true


sudo rm -rf /srv/keycloak-data/*
sudo ls -la /srv/keycloak-data/
sudo chown -R 1000:1000 /srv/keycloak-data
sudo chmod -R 755 /srv/keycloak-data