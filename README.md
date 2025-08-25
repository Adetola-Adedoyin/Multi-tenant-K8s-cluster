# Kubernetes Bare Metal Deployment

A production-ready solution for deploying Kubernetes clusters on bare metal Ubuntu instances with multi-tenant namespace isolation and RBAC.

## Features

- **Multi-node cluster setup** - Automated 3-node cluster deployment
- **Customer isolation** - Secure namespace-based multi-tenancy
- **RBAC integration** - Fine-grained access control
- **Production ready** - Calico CNI, containerd runtime
- **Easy management** - Simple scripts for deployment and customer onboarding

## Prerequisites

| Requirement | Specification |
|-------------|---------------|
| OS | Ubuntu 20.04+ |
| Nodes | 3 instances (1 master, 2 workers) |
| RAM | 2GB minimum per node |
| Access | Root/sudo privileges |
| Network | Private network connectivity |

## Quick Start

```bash
# 1. Clone and setup cluster
git clone <repository>
cd K8s-deployment
chmod +x *.sh

# 2. Deploy cluster (run on all nodes)
./k8s-bare-metal.sh

# 3. Create customer namespace (run on master)
./k8s-ns.sh
```

## Project Structure

```
K8s-deployment/
├── k8s-bare-metal.sh         # Cluster setup automation
├── k8s-ns.sh                # Customer namespace creation
├── docs/
│   ├── cluster-setup.md      # Detailed setup guide
│   ├── namespace-management.md # RBAC and isolation
│   └── troubleshooting.md    # Common issues and fixes
├── CONTRIBUTING.md           # Development guidelines
└── README.md                # This file
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Master Node   │    │  Worker Node 1  │    │  Worker Node 2  │
│                 │    │                 │    │                 │
│ • API Server    │    │ • kubelet       │    │ • kubelet       │
│ • etcd          │    │ • kube-proxy    │    │ • kube-proxy    │
│ • Scheduler     │    │ • containerd    │    │ • containerd    │
│ • Controller    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Calico CNI     │
                    │  Pod Network    │
                    └─────────────────┘
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Cluster Setup](docs/cluster-setup.md) | Complete installation walkthrough |
| [Namespace Management](docs/namespace-management.md) | Customer isolation and RBAC |
| [Troubleshooting](docs/troubleshooting.md) | Common issues and solutions |

## Security Features

- ✅ **Namespace Isolation** - Customers can only access their resources
- ✅ **RBAC Enforcement** - Role-based access control
- ✅ **Service Accounts** - Minimal privilege principle
- ✅ **Network Policies** - Traffic segmentation via Calico
- ✅ **Secure Defaults** - Swap disabled, proper configurations

## Customer Onboarding

### 1. Create Namespace and Service Account
```bash
kubectl create namespace acme-corp
kubectl create serviceaccount customer1 -n acme-corp
```

### 2. RBAC Role Configuration
```yaml
# customer1-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: acme-corp
  name: customer1-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "deployments", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
```

### 3. Role Binding
```yaml
# customer1-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: customer1-rolebinding
  namespace: acme-corp
subjects:
- kind: ServiceAccount
  name: customer1
  namespace: acme-corp
roleRef:
  kind: Role
  name: customer1-role
  apiGroup: rbac.authorization.k8s.io
```

### 4. Customer Kubeconfig
```yaml
# customer1-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://<MASTER-IP>:6443
    certificate-authority-data: <BASE64-CA-CERT>
  name: k8s-cluster
contexts:
- context:
    cluster: k8s-cluster
    namespace: acme-corp
    user: customer1
  name: customer1-context
current-context: customer1-context
users:
- name: customer1
  user:
    token: <CUSTOMER-TOKEN>
```

### 5. Apply Configurations
```bash
# Apply RBAC
kubectl apply -f customer1-role.yaml
kubectl apply -f customer1-rolebinding.yaml

# Generate token and CA cert
kubectl create token customer1 -n acme-corp
base64 -w0 /etc/kubernetes/pki/ca.crt

# Update kubeconfig with actual values
# Replace <MASTER-IP>, <BASE64-CA-CERT>, <CUSTOMER-TOKEN>
```

### 6. Customer Usage
```bash
# Customer uses their kubeconfig
kubectl --kubeconfig=customer1-kubeconfig.yaml get pods
kubectl --kubeconfig=customer1-kubeconfig.yaml create deployment web --image=nginx
kubectl --kubeconfig=customer1-kubeconfig.yaml expose deployment web --port=80

# Or set environment variable
export KUBECONFIG=customer1-kubeconfig.yaml
kubectl get pods
```

## Monitoring

```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A

# Monitor resources
kubectl top nodes
kubectl top pods -A
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT License - see LICENSE file for details.

## Support

- 📖 [Documentation](docs/)
- 🐛 [Troubleshooting Guide](docs/troubleshooting.md)
- 💬 Create an issue for questions or bugs