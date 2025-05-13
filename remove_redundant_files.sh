#!/bin/bash

# Script to remove redundant or useless files
# This script will move them to a backup directory instead of permanently deleting them

# Create backup directory
BACKUP_DIR="/workspaces/Kubernetes-Cluster/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Created backup directory: $BACKUP_DIR"

# Function to move files to backup
backup_file() {
    if [ -f "$1" ]; then
        local dir=$(dirname "$BACKUP_DIR/$1")
        mkdir -p "$dir"
        mv "$1" "$BACKUP_DIR/$1"
        echo "Moved $1 to backup"
    else
        echo "File $1 does not exist, skipping"
    fi
}

# Function to backup directories
backup_dir() {
    if [ -d "$1" ]; then
        local dir=$(dirname "$BACKUP_DIR/$1")
        mkdir -p "$dir"
        mv "$1" "$BACKUP_DIR/$1"
        echo "Moved directory $1 to backup"
    else
        echo "Directory $1 does not exist, skipping"
    fi
}

echo "Backing up redundant files..."

# 1. Root scripts that duplicate functionality in scripts/
backup_file "/workspaces/Kubernetes-Cluster/deploy.sh"
backup_file "/workspaces/Kubernetes-Cluster/run-all.sh"
backup_file "/workspaces/Kubernetes-Cluster/verify.sh"
backup_file "/workspaces/Kubernetes-Cluster/setup-local.sh"

# 2. Redundant Kubernetes configuration files (since all-in-one.yaml exists)
backup_file "/workspaces/Kubernetes-Cluster/k8s/namespace.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/configmap.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/secrets.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/deployment.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/service.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/mongodb-deployment.yaml"
backup_file "/workspaces/Kubernetes-Cluster/k8s/mongodb-service.yaml"

# 3. Duplicate app documentation (already exists in main documentation)
if [ -d "/workspaces/Kubernetes-Cluster/app/documentation" ]; then
    backup_dir "/workspaces/Kubernetes-Cluster/app/documentation"
fi

# 4. Redundant CI/CD setup scripts (if using GitHub Actions)
backup_file "/workspaces/Kubernetes-Cluster/scripts/setup-jenkins.sh"
backup_file "/workspaces/Kubernetes-Cluster/scripts/setup-runner.sh"

echo "Backup process complete. All redundant files have been moved to $BACKUP_DIR"
echo "To restore any files, you can move them back from the backup directory."
