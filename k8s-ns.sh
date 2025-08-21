#To create namespaces for customers 

kubectl create namespace acme-corp #<replace with your customer name>

#verify the namespace is created:

kubectl get ns

#Create a Service Account for the Customer

kubectl create serviceaccount customer1 -n acme-corp #<replace customer1 with prefered name>

#verify

kubectl get serviceaccount -n acme-corp

#Create a Role for Namespace Access

sudo nano customer1-role.yaml

#--input this 
 apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: acme-corp
  name: customer1-role
rules:
- apiGroups: [""]           # core API group
  resources: ["pods", "services", "deployments", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]
- apiGroups: ["apps"]       # apps API group
  resources: ["deployments", "statefulsets", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]

#press ctrl+O, enter ctrl+X

#apply

kubectl apply -f customer1-role.yaml

#Bind the Role to the Service Account

sudo nano customer1-rolebinding.yaml

#input this 
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

#press ctrl+O, enter ctrl+X

#apply

kubectl apply -f customer1-rolebinding.yaml

#create token

kubectl create token customer1 -n acme-corp

#create certificate-authority-data:

base64 -w0 /etc/kubernetes/pki/ca.crt

#create a config file

sudo nano customer1-kubeconfig.yaml

#--input this 
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

# Replace:

# <CUSTOMER1-TOKEN-HERE> with the token you created.
# <BASE64-CA-CERT-HERE> with the base64-encoded ca.crt

# Verify the kubeconfig
# Make sure it works by running:

kubectl --kubeconfig=customer1-kubeconfig.yaml get pods

# Customer can deploy containers
# The customer can now deploy applications in their namespace using normal kubectl commands. 
# For example:

kubectl --kubeconfig=customer1-kubeconfig.yaml create deployment web --image=nginx
kubectl --kubeconfig=customer1-kubeconfig.yaml expose deployment web --port=80 --type=ClusterIP

#They can also create Services, ConfigMaps, etc., but only in acme-corp

# Optional: Test role restrictions
# You can test that the customer cannot access other namespaces:

kubectl --kubeconfig=customer1-kubeconfig.yaml get pods -n kube-system

#It should return Error from server (Forbidden)

# The customer can use the kubeconfig from anywhere that can reach your Kubernetes API server. Basically, they need network access to the master node’s API (port 6443), and a machine with kubectl installed. Here’s the breakdown:

# 1. On their local machine

# Install kubectl (Linux, macOS, Windows).

# Place the customer1-kubeconfig.yaml somewhere, e.g., ~/.kube/customer1-kubeconfig.yaml.

# Run commands like:

kubectl --kubeconfig=~/.kube/customer1-kubeconfig.yaml get pods


# 2. On a cloud VM / server

# If the customer wants to automate or run CI/CD pipelines, they can put the kubeconfig on a VM or container.

# As long as the machine can reach https://<MASTER_IP>:6443, they can deploy resources in their namespace.


# 3. Using KUBECONFIG environment variable

# Instead of typing --kubeconfig every time, they can export it:

export KUBECONFIG=/path/to/customer1-kubeconfig.yaml
kubectl get pods

# Now all kubectl commands automatically use their namespace.
