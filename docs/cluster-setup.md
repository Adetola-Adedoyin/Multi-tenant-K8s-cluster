# Kubernetes Cluster Setup Guide

## Overview
This guide walks through setting up a 3-node Kubernetes cluster on Ubuntu instances using the `k8s-bare-metal.sh` script.

## Architecture
- **Master Node**: Controls the cluster, runs API server, scheduler, and controller manager
- **Worker Nodes**: Run application workloads and pods

## Prerequisites
- 3 Ubuntu 20.04+ instances
- 2GB+ RAM per node
- Network connectivity between nodes
- Sudo access

## Step-by-Step Setup

### 1. System Preparation
```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Set hostnames
sudo hostnamectl set-hostname k8s-master   # on master
sudo hostnamectl set-hostname k8s-worker1 # on worker1
sudo hostnamectl set-hostname k8s-worker2 # on worker2
```

### 2. Network Configuration
```bash
# Get private IPs
hostname -I

# Update /etc/hosts on all nodes
<master-private-ip> k8s-master
<worker1-private-ip> k8s-worker1
<worker2-private-ip> k8s-worker2
```

### 3. Disable Swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 4. Install Container Runtime
```bash
# Install containerd
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 5. Install Kubernetes Components
```bash
# Add Kubernetes repository
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubeadm, kubelet, kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### 6. Initialize Cluster (Master Only)
```bash
# Initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 7. Join Worker Nodes
```bash
# Generate join command (on master)
sudo kubeadm token create --print-join-command

# Run the join command on each worker node
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

## Verification

### Check Cluster Status
```bash
kubectl get nodes
kubectl get pods -n kube-system -o wide
```

### Test Deployment
```bash
# Deploy test application
kubectl run nginx --image=nginx --port=80
kubectl expose pod nginx --type=NodePort --port=80

# Verify
kubectl get pods -o wide
kubectl get svc
```

## Troubleshooting

### Common Issues
- **Nodes not ready**: Check CNI installation
- **Pod network issues**: Verify Calico deployment
- **Join failures**: Regenerate tokens or check firewall

### Required Ports
- **Master**: 6443, 2379-2380, 10250-10252
- **Workers**: 10250, 30000-32767

## Next Steps
- [Set up customer namespaces](namespace-management.md)
- Configure monitoring and logging
- Implement backup strategies