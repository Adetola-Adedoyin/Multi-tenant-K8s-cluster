#!/bin/bash
set -euo pipefail

# ========= CONFIG ==========
KUBECONFIG_PATH="/home/ubuntu/tenants"
CLUSTER_NAME="k8s-cluster"
CLUSTER_SERVER="https://$(hostname -I | awk '{print $1}'):6443"
# ===========================

echo "🔹 Welcome to Tenant Creator 🔹"

# 1. Ask for namespace
read -p "Enter tenant namespace name: " TENANT
if [[ -z "$TENANT" ]]; then
  echo "❌ Namespace name cannot be empty!"
  exit 1
fi

# Check if namespace already exists
if kubectl get ns "$TENANT" >/dev/null 2>&1; then
  echo "⚠️ Namespace $TENANT already exists. Exiting..."
  exit 1
fi

# 2. Ask for username
read -p "Enter username for this tenant: " USER
if [[ -z "$USER" ]]; then
  echo "❌ Username cannot be empty!"
  exit 1
fi

# 3. Ask for resource quotas
echo "👉 Enter resource quota for tenant $TENANT"
read -p "CPU requests (e.g. 2): " REQ_CPU
read -p "Memory requests (e.g. 2Gi): " REQ_MEM
read -p "CPU limits (e.g. 4): " LIM_CPU
read -p "Memory limits (e.g. 4Gi): " LIM_MEM
read -p "Storage (e.g. 10Gi): " STORAGE

echo "✅ Creating namespace: $TENANT"
kubectl create namespace "$TENANT"

# 4. ResourceQuota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ${TENANT}-quota
  namespace: $TENANT
spec:
  hard:
    requests.cpu: "$REQ_CPU"
    requests.memory: "$REQ_MEM"
    limits.cpu: "$LIM_CPU"
    limits.memory: "$LIM_MEM"
    requests.storage: "$STORAGE"
EOF

# 5. LimitRange
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: ${TENANT}-limits
  namespace: $TENANT
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "200m"
      memory: "256Mi"
    type: Container
EOF

# 6. ServiceAccount
kubectl create serviceaccount ${USER}-sa -n $TENANT

# 7. RoleBinding
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${USER}-rb
  namespace: $TENANT
subjects:
- kind: ServiceAccount
  name: ${USER}-sa
  namespace: $TENANT
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: rbac.authorization.k8s.io
EOF

# 8. Extract token
SECRET_NAME=$(kubectl get sa ${USER}-sa -n $TENANT -o jsonpath='{.secrets[0].name}')
USER_TOKEN=$(kubectl get secret $SECRET_NAME -n $TENANT -o jsonpath='{.data.token}' | base64 --decode)

# 9. Generate kubeconfig
mkdir -p $KUBECONFIG_PATH
KUBECONFIG_FILE="$KUBECONFIG_PATH/${USER}-${TENANT}-kubeconfig"

cat <<EOF > $KUBECONFIG_FILE
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $(kubectl config view --raw -o jsonpath="{.clusters[0].cluster.certificate-authority-data}")
    server: $CLUSTER_SERVER
  name: $CLUSTER_NAME
contexts:
- context:
    cluster: $CLUSTER_NAME
    namespace: $TENANT
    user: ${USER}-${TENANT}
  name: ${USER}@${TENANT}
current-context: ${USER}@${TENANT}
users:
- name: ${USER}-${TENANT}
  user:
    token: $USER_TOKEN
EOF

# 10. Apply NetworkPolicy (Phase 2: Tenant Isolation)
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${TENANT}-deny-cross-namespace
  namespace: $TENANT
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}   # Allow pods in same namespace
  egress:
  - to:
    - podSelector: {}   # Allow pods in same namespace
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system   # Allow DNS/Core services
EOF

echo "🎉 Tenant $TENANT with user $USER created successfully!"
echo "📂 Kubeconfig saved at: $KUBECONFIG_FILE"
echo "👉 To use it: export KUBECONFIG=$KUBECONFIG_FILE"
echo "🔒 NetworkPolicy applied: Tenant $TENANT is isolated from other namespaces"
echo "🔹 Happy K8s-ing! 🔹"
