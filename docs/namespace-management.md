# Kubernetes Namespace Management Guide

## Overview
This guide covers creating isolated customer namespaces with proper RBAC using the `k8s-ns.sh` script.

## Namespace Isolation Strategy
- Each customer gets a dedicated namespace
- Service accounts with minimal required permissions
- RBAC roles limiting access to customer's namespace only
- Individual kubeconfig files for customer access

## Setup Process

### 1. Create Customer Namespace
```bash
kubectl create namespace acme-corp  # Replace with customer name
kubectl get ns  # Verify creation
```

### 2. Create Service Account
```bash
kubectl create serviceaccount customer1 -n acme-corp
kubectl get serviceaccount -n acme-corp
```

### 3. Define RBAC Role
Create `customer1-role.yaml`:
```yaml
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

Apply the role:
```bash
kubectl apply -f customer1-role.yaml
```

### 4. Create Role Binding
Create `customer1-rolebinding.yaml`:
```yaml
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

Apply the binding:
```bash
kubectl apply -f customer1-rolebinding.yaml
```

### 5. Generate Access Credentials
```bash
# Create token
kubectl create token customer1 -n acme-corp

# Get CA certificate
base64 -w0 /etc/kubernetes/pki/ca.crt
```

### 6. Create Customer Kubeconfig
Create `customer1-kubeconfig.yaml`:
```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://172.31.84.67:6443
    certificate-authority-data: <BASE64-CA-CERT-HERE>
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
    token: <CUSTOMER1-TOKEN-HERE>
```

Replace placeholders:
- `<CUSTOMER1-TOKEN-HERE>`: Token from step 5
- `<BASE64-CA-CERT-HERE>`: CA certificate from step 5

## Customer Usage

### Local Machine Setup
```bash
# Install kubectl
# Place kubeconfig file
kubectl --kubeconfig=customer1-kubeconfig.yaml get pods

# Or set environment variable
export KUBECONFIG=/path/to/customer1-kubeconfig.yaml
kubectl get pods
```

### Example Deployments
```bash
# Deploy application
kubectl create deployment web --image=nginx
kubectl expose deployment web --port=80 --type=ClusterIP

# Create ConfigMap
kubectl create configmap app-config --from-literal=env=production

# Create Secret
kubectl create secret generic app-secret --from-literal=password=secret123
```

## Security Features

### Namespace Isolation
- Customers can only access their assigned namespace
- No visibility into other namespaces or cluster resources
- Network policies can be applied for additional isolation

### RBAC Permissions
Current role allows:
- **Core resources**: pods, services, configmaps, secrets
- **Apps resources**: deployments, statefulsets, replicasets
- **Verbs**: Full CRUD operations within namespace

### Testing Restrictions
```bash
# This should fail (forbidden)
kubectl --kubeconfig=customer1-kubeconfig.yaml get pods -n kube-system
kubectl --kubeconfig=customer1-kubeconfig.yaml get nodes
```

## Best Practices

### Resource Quotas
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: customer1-quota
  namespace: acme-corp
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "10"
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: acme-corp
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

## Automation

### Script Template
```bash
#!/bin/bash
CUSTOMER_NAME=$1
NAMESPACE=$2

kubectl create namespace $NAMESPACE
kubectl create serviceaccount $CUSTOMER_NAME -n $NAMESPACE
# Apply role and rolebinding templates
# Generate kubeconfig
```

## Troubleshooting

### Common Issues
- **Token expiration**: Regenerate tokens periodically
- **Permission denied**: Check RBAC configuration
- **Network access**: Verify API server accessibility

### Verification Commands
```bash
kubectl auth can-i --list --as=system:serviceaccount:acme-corp:customer1 -n acme-corp
kubectl get rolebindings -n acme-corp
kubectl describe role customer1-role -n acme-corp
```