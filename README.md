# Keycloak & Kong on Kubernetes via Pulumi YAML (Ubuntu 26 / LXD + Cilium CNI)

Declarative Infrastructure-as-Code with **Pulumi YAML** (`pulumi up`) to deploy and test **Keycloak 26 (Quarkus)** backed by **PostgreSQL**, routed through **Kong Gateway** on a **Cilium eBPF** Kubernetes cluster.

---

## 🏗️ Architecture Overview

```
External Client (Browser / Postman / cURL)
                   │
                   ▼  VIP: 192.168.100.240
┌─────────────────────────────────────────────────────────┐
│                     Kong Gateway                        │
│                                                         │
│  Route: keycloak.192.168.100.240.nip.io                 │
│      └──► Proxies to Keycloak (Auth, Admin, Tokens)     │
│                                                         │
│  Route: 192.168.100.240/echo                            │
│      ├──► Kong JWT Plugin (Validates Keycloak JWT)      │
│      └──► Proxies to Echo Pod in kong-lab               │
└──────────────────────────┬──────────────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
   ┌───────────────────┐       ┌───────────────────┐
   │ Keycloak Pod      │       │ Echo Pod (App)    │
   │ (namespace: keycloak)     │ (namespace: kong-lab)
   └─────────┬─────────┘       └───────────────────┘
             ▼
   ┌───────────────────┐
   │ PostgreSQL DB     │
   │ (namespace: keycloak)
   └───────────────────┘
```

### Cluster Environment (Ubuntu 26 / LXD)
- **Host:** `k8s`
- **Control Plane (`k8master`):** `192.168.100.10` (access via `ssh k8master`)
- **Worker Node (`k8worker1`):** `192.168.100.11` (access via `ssh k8worker1`)
- **CNI:** Cilium (eBPF)
- **Ingress Gateway:** Kong Gateway (`192.168.100.240:80 / 443`)
- **Keycloak Hostname:** `http://keycloak.192.168.100.240.nip.io`

---

## 📁 Repository Structure

```
.
├── Pulumi.yaml                      # Pulumi YAML program defining all K8s resources
├── Pulumi.dev.yaml                  # Stack configuration (VIPs, passwords, etc.)
├── k8s/                             # (Reference raw manifests if needed)
│   ├── 00-namespace.yaml
│   ├── 01-postgres.yaml
│   ├── 02-keycloak.yaml
│   ├── 03-kong-ingress.yaml
│   └── 04-kong-jwt-echo-plugin.yaml
├── scripts/
│   ├── deploy.sh                    # Wrapper calling 'pulumi up --yes'
│   ├── destroy.sh                   # Wrapper calling 'pulumi destroy --yes'
│   ├── test-m2m.sh                  # Test Machine-to-Machine (Client Credentials)
│   ├── test-user-token.sh           # Test End-User login & JWT generation
│   └── test-kong-protected-echo.sh  # Test Kong JWT authorization against echo pod
└── tests/
    └── keycloak-suite.http          # HTTP REST tests (VS Code / REST Client compatible)
```

---

## 🚀 Pulumi Workflow (on `k8s` host or `k8master`)

### 1. Preview Changes
```bash
pulumi preview
```

### 2. Deploy the Entire Stack
```bash
pulumi up
```
*(Or use `./scripts/deploy.sh`)*

Pulumi will create the `keycloak` namespace, deploy PostgreSQL, wait for it to be ready, launch Keycloak 26 (Quarkus), and create the Kong Ingress rule.

At the end of the deployment, Pulumi prints the outputs:
```text
Outputs:
    adminUsername       : "admin"
    keycloakAdminUrl    : "http://keycloak.192.168.100.240.nip.io/admin"
    keycloakWellKnownUrl: "http://keycloak.192.168.100.240.nip.io/realms/lab-realm/.well-known/openid-configuration"
```

### 3. Teardown / Reset
```bash
pulumi destroy
```
*(Or use `./scripts/destroy.sh`)*

---

## 🧪 Testing Roadmap

All testing scripts run directly on Linux with `bash`, `curl`, and `jq`:

### 1. Test 1 - Create Realm & User in Admin Console
1. Open [http://keycloak.192.168.100.240.nip.io/admin](http://keycloak.192.168.100.240.nip.io/admin)
   - **User:** `admin`
   - **Password:** `AdminMasterPassword123!`
2. Create Realm: `lab-realm`
3. Create Client: `demo-app` (Public client)
4. Create Confidential Client: `backend-service` (Service account enabled)
5. Create User: `alice` / `Password123!`

### 2. Test 2 - Machine-to-Machine Auth (M2M)
```bash
./scripts/test-m2m.sh <YOUR_BACKEND_SERVICE_CLIENT_SECRET>
```

### 3. Test 3 - User Authentication & Token Inspection
```bash
./scripts/test-user-token.sh alice Password123!
```

### 4. Test 4 - Kong Gateway API Protection
```bash
./scripts/test-kong-protected-echo.sh
```
- Request **without** Bearer token &rarr; `401 Unauthorized`
- Request **with** Keycloak Bearer token &rarr; `200 OK`
