#!/usr/bin/env bash
# 2200-install-kong.sh — run INSIDE k8master, after 06-cilium-lb-ipam.sh.
# Installs the Kubernetes Gateway API CRDs + Kong (kong/ingress chart, the
# current recommended chart for new installs — combines the Ingress
# Controller and the Kong Gateway data plane).
set -euo pipefail
export KUBECONFIG=/root/.kube/config

echo "==> Installing Gateway API CRDs"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml

echo "==> Adding the Kong Helm repo"
helm repo add kong https://charts.konghq.com
helm repo update

echo "==> Installing Kong (namespace: kong)"
helm upgrade --install kong kong/ingress \
  --namespace kong --create-namespace \
  --set gateway.type=LoadBalancer \
  --set gateway.proxy.externalTrafficPolicy=Local

echo "==> Waiting for the Kong proxy Service to get a LoadBalancer IP from Cilium"
for i in $(seq 1 30); do
  PROXY_IP=$(kubectl get svc -n kong kong-gateway-proxy \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  [ -n "${PROXY_IP}" ] && break
  sleep 5
done

if [ -z "${PROXY_IP:-}" ]; then
  echo "==> Still pending — check: kubectl get svc -n kong kong-gateway-proxy"
else
  echo "==> Kong proxy is live at: http://${PROXY_IP}"
  echo "    (expect a 404 with 'no Route matched' until you apply an HTTPRoute)"
fi

kubectl get pods -n kong
kubectl get svc -n kong
