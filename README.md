# Keycloak & Kong on Kubernetes (Ubuntu 26 / LXD + Cilium CNI)

End-to-end deployment, configuration, and testing suite for **Keycloak 26 (Quarkus)** integrated with **Kong Gateway** and **Cilium eBPF** on Kubernetes running in **Ubuntu 26 / LXD containers**.

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
├── k8s/
│   ├── 00-namespace.yaml            # Dedicated keycloak namespace
│   ├── 01-postgres.yaml             # PostgreSQL database deployment & service
│   ├── 02-keycloak.yaml             # Keycloak 26 (Quarkus) deployment & service
│   ├── 03-kong-ingress.yaml         # Kong Ingress exposing Keycloak via nip.io
│   └── 04-kong-jwt-echo-plugin.yaml # Kong JWT Plugin protecting kong-lab/echo
├── scripts/
│   ├── deploy.sh                    # Deploy all manifests to Kubernetes
│   ├── test-m2m.sh                  # Test Machine-to-Machine (Client Credentials)
│   ├── test-user-token.sh           # Test End-User login & JWT generation
│   └── test-kong-protected-echo.sh  # Test Kong JWT authorization against echo pod
└── tests/
    └── keycloak-suite.http          # HTTP REST tests (VS Code / REST Client compatible)
```

---

## 🚀 Deployment from `k8master` (or Host `k8s`)

### 1. Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

### 2. Run Deployment
```bash
./scripts/deploy.sh
```
Or apply manifests directly:
```bash
kubectl apply -f k8s/
```

### 3. Access Keycloak Admin Console
Open your browser:
- **URL:** [http://keycloak.192.168.100.240.nip.io/admin](http://keycloak.192.168.100.240.nip.io/admin)
- **Username:** `admin`
- **Password:** `AdminMasterPassword123!`

---

## 🧪 Testing Roadmap

All testing scripts run directly on Linux with `bash`, `curl`, and optional `jq`:

### 1. Test 1 - Create Realm & User in Admin Console
- Create realm: `lab-realm`
- Create client: `demo-app` (Public client)
- Create confidential client: `backend-service` (Service account enabled)
- Create user: `alice` / `Password123!`

### 2. Test 2 - Machine-to-Machine Auth (M2M)
```bash
./scripts/test-m2m.sh <YOUR_BACKEND_SERVICE_CLIENT_SECRET>
```

### 3. Test 3 - User Authentication & Token Inspection
```bash
./scripts/test-user-token.sh alice Password123!
```
*(Decodes JWT payload and saves token to `/tmp/keycloak/token.txt`)*

### 4. Test 4 - Kong Gateway API Protection
```bash
# Apply the Kong JWT plugin first:
kubectl apply -f k8s/04-kong-jwt-echo-plugin.yaml

# Run verification:
./scripts/test-kong-protected-echo.sh
```
- Request **without** Bearer token &rarr; `401 Unauthorized`
- Request **with** Keycloak Bearer token &rarr; `200 OK`
