# Keycloak & Kong on Kubernetes (Cilium CNI)

End-to-end deployment, configuration, and testing suite for **Keycloak 26 (Quarkus)** integrated with **Kong Gateway** and **Cilium eBPF** on Kubernetes.

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

### Cluster Environment
- **Control Plane (`k8master`):** `192.168.100.10`
- **Worker Node (`k8worker1`):** `192.168.100.11`
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
│   ├── deploy.ps1                   # Deploy all manifests to Kubernetes
│   ├── test-m2m.ps1                 # Test Machine-to-Machine (Client Credentials)
│   ├── test-user-token.ps1          # Test End-User login & JWT generation
│   └── test-kong-protected-echo.ps1 # Test Kong JWT authorization against echo pod
└── tests/
    └── keycloak-suite.http          # HTTP REST tests (VS Code / REST Client compatible)
```

---

## 🚀 Quick Start

### 1. Deploy Keycloak & Database
Run PowerShell deploy script:
```powershell
.\scripts\deploy.ps1
```
Or apply manifests manually:
```bash
kubectl apply -f k8s/
```

### 2. Access the Keycloak Admin Console
Open your browser:
- **URL:** [http://keycloak.192.168.100.240.nip.io/admin](http://keycloak.192.168.100.240.nip.io/admin)
- **Username:** `admin`
- **Password:** `AdminMasterPassword123!`

---

## 🧪 Testing Roadmap

1. **Test 1 - Admin Console & Realm Creation:** Create `lab-realm`, users (`alice`), and roles (`api-user`).
2. **Test 2 - Machine-to-Machine Auth (M2M):** Run `.\scripts\test-m2m.ps1` to test the OAuth2 Client Credentials flow.
3. **Test 3 - User Authentication:** Run `.\scripts\test-user-token.ps1` to obtain User Access & Refresh tokens.
4. **Test 4 - Kong JWT Validation:** Run `.\scripts\test-kong-protected-echo.ps1` to verify Kong blocks unauthenticated requests and permits valid Keycloak JWTs.
5. **Test 5 - Multi-Factor Authentication (MFA):** Enable OTP in Keycloak and verify QR code setup via the Account console.
