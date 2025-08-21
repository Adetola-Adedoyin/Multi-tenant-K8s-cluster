# Kubernetes Bare Metal Deployment

A complete guide for setting up a Kubernetes cluster on bare metal Ubuntu instances and managing customer namespaces with RBAC.

## Overview

This project provides scripts and documentation for:
- Setting up a multi-node Kubernetes cluster on Ubuntu
- Creating isolated customer namespaces with proper RBAC
- Deploying and managing containerized applications

## Prerequisites

- 3 Ubuntu instances (1 master, 2 workers)
- Root/sudo access on all nodes
- Network connectivity between nodes
- Minimum 2GB RAM per node

## Quick Start

1. **Set up the cluster:**
   ```bash
   ./k8s-bare-metal.sh
   ```

2. **Create customer namespace:**
   ```bash
   ./k8s-ns.sh
   ```

## Project Structure

```
K8s-deployment/
├── k8s-bare-metal.sh    # Cluster setup script
├── k8s-ns.sh           # Namespace and RBAC setup
└── README.md           # This documentation
```

## Scripts

### k8s-bare-metal.sh
Complete Kubernetes cluster setup including:
- System preparation and hostname configuration
- Container runtime (containerd) installation
- Kubernetes components installation
- Cluster initialization and networking
- Basic testing and verification

### k8s-ns.sh
Customer namespace management with:
- Namespace creation
- Service account setup
- RBAC role and binding configuration
- Kubeconfig generation for customers

## Usage

See individual script documentation:
- [Cluster Setup Guide](docs/cluster-setup.md)
- [Namespace Management Guide](docs/namespace-management.md)

## Security

- Swap disabled for Kubernetes compliance
- RBAC enforced for namespace isolation
- Service accounts with minimal required permissions
- Network policies via Calico CNI

## Support

For issues or questions, refer to the troubleshooting section in the documentation or check the Kubernetes official documentation.