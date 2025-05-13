#!/bin/bash
# cleanup.sh - Script to clean up Kubernetes resources

# Source common functions
if [ -f "scripts/common.sh" ]; then
    source scripts/common.sh
else
    echo "❌ Common script not found!"
    exit 1
fi

echo "====================================================="
echo "🧹 Kubernetes Cluster Cleanup"
echo "====================================================="

# Check if --dry-run flag is provided
DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in dry-run mode (no actual changes will be made)"
fi

# Load environment variables
load_env

if [ "$DRY_RUN" = true ]; then
    echo "Dry run: would delete the following resources:"
    echo "- Kubernetes namespace: mern-app"
    echo "- Kubernetes deployments: mern-auth-app, mongodb"
    echo "- Kubernetes services: mern-auth-service, mongodb-service"
    echo "- Kubernetes configmaps and secrets"
    echo "Would stop Minikube instance"
else
    # Show current state before cleanup
    echo "Current Kubernetes resources:"
    kubectl get all -n mern-app
    
    # Confirm before cleanup
    read -p "Are you sure you want to clean up all resources? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        cleanup
    else
        echo "Cleanup cancelled."
        exit 0
    fi
fi

echo "====================================================="
echo "✅ Cleanup operation completed!"
echo "====================================================="
