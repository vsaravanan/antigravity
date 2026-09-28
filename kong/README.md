# Kong Learning Lab: Pulumi YAML Only

This lab uses Pulumi, but everything you read and edit is YAML.

## Relationship to your existing Kong install

You already have a separate Pulumi Python project here:

```text
../kong-pulumi-example
```

That project installs Kong itself in the `kong` namespace. It creates resources like:

```text
service/kong-d19f3a41-controller-metrics
service/kong-d19f3a41-controller-validation-webhook
service/kong-d19f3a41-gateway-admin
service/kong-d19f3a41-gateway-manager
service/kong-d19f3a41-gateway-proxy
pod/kong-d19f3a41-controller-...
pod/kong-d19f3a41-gateway-...
```

This YAML-only project does not install Kong again. It assumes Kong is already running and only creates learning resources:

```text
namespace/kong-lab
deployment/echo
service/echo
ingress/echo
kongplugin/...
kongconsumer/demo-client
namespace/monitoring
prometheus resources
```

Use `../kong-pulumi-example` to manage the Kong installation. Use this `kong` folder to manage routes, plugins, and Prometheus learning examples.

Pulumi entry point:

```text
Pulumi.yaml
```

Pulumi loads one selected Kong learning manifest:

```text
yaml/00-echo-app.yaml
yaml/01-echo-route.yaml
yaml/02-rate-limit.yaml
yaml/03-key-auth.yaml
```

Prometheus is separate, so it does not make the echo route files huge:

```text
yaml/06-prometheus.yaml
```

## Config values

Use `routeManifest` for the Kong route lesson:

```bash
pulumi config set routeManifest yaml/00-echo-app.yaml
```

Use `observabilityManifest` for Prometheus:

```bash
pulumi config set observabilityManifest yaml/06-prometheus.yaml
```

By default, `observabilityManifest` points to `yaml/00-empty-list.yaml`, which means Prometheus is not installed yet.

## 1. Fast routing

Run this from the `kong` folder:

```bash
pulumi stack init dev
pulumi config set proxyBaseUrl https://192.168.100.240
pulumi config set routeManifest yaml/00-echo-app.yaml
pulumi up
pulumi config set routeManifest yaml/01-echo-route.yaml
pulumi up
```

If you already created the stack earlier, select it instead:

```bash
pulumi stack select dev
```

If `pulumi stack select dev` says `no stack named 'dev' found`, then this `kong` Pulumi project does not have a `dev` stack yet. Create it once:

```bash
pulumi stack init dev
```

Check what Pulumi created:

```bash
kubectl get pods,svc,ingress -n kong-lab
```

Test from Windows:

```powershell
curl.exe -k https://192.168.100.240/echo
```

Test through the Ubuntu host DNAT and NodePort path:

```bash
curl -k https://192.168.50.84:32173/echo
curl http://192.168.50.84:30163/echo
```

If `/echo` responds, this path is working:

```text
client -> Kong proxy -> Ingress route -> Kubernetes Service -> echo pod
```

## 2. Rate limiting

```bash
pulumi config set routeManifest yaml/02-rate-limit.yaml
pulumi preview
pulumi up
```

Test from Windows:

```powershell
1..6 | ForEach-Object { curl.exe -k -i https://192.168.100.240/echo }
```

You should see `429 Too Many Requests` after the limit is reached.

This step also creates `secret/demo-client-key`. The next lesson uses that
existing Secret when it creates the Kong consumer.

## 3. API key authentication

```bash
pulumi config set routeManifest yaml/03-key-auth.yaml
pulumi preview
pulumi up
```

If the preview fails with `consumer referenced non-existent credentials secret`,
go back and apply lesson 2 first:

```bash
pulumi config set routeManifest yaml/02-rate-limit.yaml
pulumi up
pulumi config set routeManifest yaml/03-key-auth.yaml
pulumi up
```

The Kong validation webhook checks that the credential Secret already exists
before it accepts the `KongConsumer`.

Without a key:

```powershell
curl.exe -k -i https://192.168.100.240/echo
```

With a key:

```powershell
curl.exe -k -i -H "apikey: learning-key-123" https://192.168.100.240/echo
```

## 4. Header injection

```bash
pulumi config set routeManifest yaml/04-header-injection.yaml
pulumi preview
pulumi up
```

Call `/echo` with the API key and look for this request header in the response:

```text
x-kong-lab: true
```

## 5. IP restriction

This intentionally blocks traffic from the Windows/LAN side of the lab:

```text
192.168.50.0/24
```

For this to work, Kong's proxy Service must preserve the real client source IP:

```bash
kubectl get svc -n kong kong-gateway-proxy -o jsonpath='{.spec.externalTrafficPolicy}{"\n"}'
```

It should print:

```text
Local
```

```bash
pulumi config set routeManifest yaml/05-ip-restriction.yaml
pulumi preview
pulumi up
```

If it prints `Cluster` or nothing, update the Kong install:

```bash
helm upgrade --install kong kong/ingress \
  --namespace kong --create-namespace \
  --set gateway.type=LoadBalancer \
  --set gateway.proxy.externalTrafficPolicy=Local
```

Undo the block by returning to the previous route lesson:

```bash
pulumi config set routeManifest yaml/04-header-injection.yaml
pulumi preview
pulumi up
```

## 6. Prometheus

Prometheus is installed separately from the echo route lessons.

It uses the Prometheus disk you already created earlier:

```text
prometheus.vdi -> prometheuspool -> prometheuspool/data -> /srv/prometheus-data -> /mnt/prometheus-data in k8master
```

Before running the lesson, check this inside `k8master`:

```bash
findmnt -T /mnt/prometheus-data
ls -ld /mnt/prometheus-data
kubectl get nodes
```

The manifest assumes the Kubernetes node name is `k8master`. If `kubectl get nodes` shows a different name, change `k8master` in `yaml/06-prometheus.yaml`.

Install Prometheus with Pulumi:

```bash
pulumi config set observabilityManifest yaml/06-prometheus.yaml
pulumi preview
pulumi up
```

Check it:

```bash
kubectl get pods,svc,pvc -n monitoring
kubectl get pv prometheuspool-prometheus-data
```

Prometheus should be available through Kong at:

```text
https://192.168.100.240/prometheus
```

To remove Prometheus but keep the echo route:

```bash
pulumi config set observabilityManifest yaml/00-empty-list.yaml
pulumi preview
pulumi up
```

## Useful checks

```bash
pulumi stack output
pulumi preview
kubectl get ingress -n kong-lab
kubectl describe ingress -n kong-lab echo
kubectl get pods,svc -n kong-lab
kubectl get kongplugin -n kong-lab
kubectl get kongconsumer -n kong-lab
```

## Cleanup

Use Pulumi cleanup, not `kubectl delete`, so Pulumi state remains correct:

```bash
pulumi destroy
pulumi stack rm dev
```

## Recommended learning order

1. Kong route works.
2. Kong plugins: rate limit, API key, header transform, IP block.
3. Prometheus + Grafana: see request count, error rate, and latency.
4. Loki: collect Kong and app logs.
5. Jaeger: trace one request across services.
6. Postgres and Redis: place real stateful backends behind Kong.
7. Keycloak: replace API keys with OIDC login.
8. Vault: store shared secrets.
9. Kafka, OpenSearch, GitLab: build the larger platform later.
