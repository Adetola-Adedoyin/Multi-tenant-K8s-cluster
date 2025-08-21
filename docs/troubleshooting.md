# Troubleshooting Guide

## Common Issues and Solutions

### Cluster Setup Issues

#### Nodes Not Ready
**Symptoms**: `kubectl get nodes` shows nodes in `NotReady` state

**Solutions**:
```bash
# Check kubelet status
sudo systemctl status kubelet

# Check CNI installation
kubectl get pods -n kube-system | grep calico

# Restart kubelet if needed
sudo systemctl restart kubelet
```

#### Pod Network Issues
**Symptoms**: Pods can't communicate or DNS resolution fails

**Solutions**:
```bash
# Verify Calico installation
kubectl get pods -n kube-system -l k8s-app=calico-node

# Check pod CIDR configuration
kubectl cluster-info dump | grep -i cidr

# Restart Calico if needed
kubectl delete pods -n kube-system -l k8s-app=calico-node
```

#### Join Command Failures
**Symptoms**: Worker nodes fail to join cluster

**Solutions**:
```bash
# Regenerate join token
sudo kubeadm token create --print-join-command

# Check firewall rules
sudo ufw status
sudo iptables -L

# Verify master node accessibility
telnet <master-ip> 6443
```

### RBAC and Namespace Issues

#### Permission Denied Errors
**Symptoms**: `Error from server (Forbidden)`

**Solutions**:
```bash
# Check current permissions
kubectl auth can-i --list --as=system:serviceaccount:namespace:serviceaccount

# Verify role binding
kubectl get rolebindings -n <namespace>
kubectl describe rolebinding <binding-name> -n <namespace>

# Check service account
kubectl get serviceaccount -n <namespace>
```

#### Token Expiration
**Symptoms**: Authentication failures with existing kubeconfig

**Solutions**:
```bash
# Create new token
kubectl create token <serviceaccount> -n <namespace>

# Update kubeconfig with new token
# Replace token field in kubeconfig file
```

### Application Deployment Issues

#### Image Pull Errors
**Symptoms**: Pods stuck in `ImagePullBackOff`

**Solutions**:
```bash
# Check image name and tag
kubectl describe pod <pod-name>

# Verify registry access
docker pull <image-name>

# Check image pull secrets if using private registry
kubectl get secrets
```

#### Resource Constraints
**Symptoms**: Pods in `Pending` state

**Solutions**:
```bash
# Check resource availability
kubectl describe nodes
kubectl top nodes

# Check resource quotas
kubectl describe quota -n <namespace>

# Check pod resource requests
kubectl describe pod <pod-name>
```

## Diagnostic Commands

### Cluster Health
```bash
# Overall cluster status
kubectl cluster-info
kubectl get componentstatuses

# Node details
kubectl get nodes -o wide
kubectl describe node <node-name>

# System pods
kubectl get pods -n kube-system
```

### Network Diagnostics
```bash
# Test DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default

# Check service endpoints
kubectl get endpoints

# Network connectivity test
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash
```

### RBAC Debugging
```bash
# Check permissions for user/service account
kubectl auth can-i <verb> <resource> --as=<user>

# List all permissions
kubectl auth can-i --list --as=<user>

# Check role definitions
kubectl get roles,rolebindings -A
```

## Log Analysis

### Kubelet Logs
```bash
sudo journalctl -u kubelet -f
sudo journalctl -u kubelet --since "1 hour ago"
```

### Container Logs
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous
```

### System Pod Logs
```bash
kubectl logs -n kube-system <pod-name>
kubectl logs -n kube-system -l component=kube-apiserver
```

## Performance Issues

### Resource Monitoring
```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -A

# Detailed resource info
kubectl describe node <node-name>
```

### Storage Issues
```bash
# Check disk usage
df -h
kubectl get pv,pvc -A

# Check storage classes
kubectl get storageclass
```

## Recovery Procedures

### Reset Cluster Node
```bash
# On worker node
sudo kubeadm reset
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/

# Rejoin cluster
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
```

### Backup and Restore
```bash
# Backup etcd (on master)
sudo ETCDCTL_API=3 etcdctl snapshot save backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Restore etcd
sudo ETCDCTL_API=3 etcdctl snapshot restore backup.db
```

## Prevention Best Practices

### Regular Maintenance
- Monitor cluster resource usage
- Update Kubernetes components regularly
- Rotate service account tokens
- Review and update RBAC policies

### Monitoring Setup
```bash
# Deploy metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check metrics
kubectl top nodes
kubectl top pods -A
```

### Security Hardening
- Enable audit logging
- Use network policies
- Implement pod security policies
- Regular security scans