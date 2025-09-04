# System setup on each Ubuntu instance
# Update and upgrade packages:

sudo apt update && sudo apt upgrade -y

#Set hostnames (to identify each node):

sudo hostnamectl set-hostname k8s-master   # on master
sudo hostnamectl set-hostname k8s-worker1 # on worker1
sudo hostnamectl set-hostname k8s-worker2 # on worker2

# Find private IPs of your nodes
# On each instance:

hostname -I

#Pick the private IP

sudo nano /etc/hosts
# Add the following lines to /etc/hosts at the bottom

<master-private-ip> k8s-master
<worker1-private-ip> k8s-worker1
<worker2-private-ip> k8s-worker2

# Disable swap (Kubernetes requires swap to be disabled):

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Dependencies to Install (on all 3 nodes)
# Container runtime (choose one):
# Recommended: containerd

sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Kubernetes tools
# Install kubeadm, kubelet, kubectl:

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#Enable bridge-nf-call-iptables
#This allows iptables to see bridged traffic (required for Calico/Flannel).

sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1

#To make it persistent across reboots:

sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Enable IPv4 forwarding

sudo sysctl -w net.ipv4.ip_forward=1

# Verify settings

cat /proc/sys/net/bridge/bridge-nf-call-iptables
cat /proc/sys/net/ipv4/ip_forward

#both should return 1

# Initialize the cluster (on master node):

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 

# Set up kubeconfig for the master node:

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install a pod network or CNI (calico, flannel, etc.):

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Join the worker nodes to the cluster:

sudo kubeadm token create --print-join-command

# Copy the join command and run it on each worker node

#verify nodes are ready:

kubectl get nodes

#Confirm all system pods are running:

kubectl get pods -n kube-system -o wide

#Deploy a quick test pod:

kubectl run nginx --image=nginx --port=80

# Verify the test pod is running:

kubectl get pods -o wide

# Expose the nginx pod as a Service
# Run this command:

kubectl expose pod nginx --type=NodePort --port=80

#Check the Service

kubectl get svc

#Get the external node IP and the NodePort assigned to the nginx service:

kubectl get nodes -o wide

# Access the nginx service using the external IP and NodePort
# Open a web browser and navigate to http://<external-node-ip>:<node-port>

