#!/bin/bash

# Script to capture screenshots/diagnostic information for the project documentation
set -e

# Source common functions
if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh"
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "Kubernetes Cluster - Documentation Screenshot Capture"
echo "====================================================="
# Check if Minikube is running
check_minikube_running() {
    if ! minikube status | grep -q "Running"; then
        echo "❌ Minikube is not running. Please start it first."
        echo "Run: minikube start"
        exit 1
    fi
    echo "✅ Minikube is running."
}

# Create directory structure
create_directory_structure() {
    local date_dir=$(date "+%Y-%m-%d")
    
    # Main directories
    mkdir -p documentation/screenshots/${date_dir}/{1-environment,2-application,3-docker,4-kubernetes,5-github-actions,6-issues}
    
    # Kubernetes subdirectories
    mkdir -p documentation/screenshots/${date_dir}/4-kubernetes/{pods,services,deployments,nodes}
    
    # Issues subdirectories
    for i in {1..5}; do
        mkdir -p documentation/screenshots/${date_dir}/6-issues/issue${i}
    done
    
    echo "✅ Directory structure created."
}

# Capture environment details
capture_environment() {
    local date_dir=$(date "+%Y-%m-%d")
    local timestamp=$(date "+%H-%M-%S")
    
    echo "Capturing environment details..."
    
    # OS information
    uname -a > documentation/screenshots/${date_dir}/1-environment/os_info_${timestamp}.txt
    cat /etc/os-release 2>/dev/null >> documentation/screenshots/${date_dir}/1-environment/os_info_${timestamp}.txt
    
    # Docker information
    docker version > documentation/screenshots/${date_dir}/1-environment/docker_version_${timestamp}.txt
    docker info > documentation/screenshots/${date_dir}/1-environment/docker_info_${timestamp}.txt
    
    # Minikube information
    minikube version > documentation/screenshots/${date_dir}/1-environment/minikube_version_${timestamp}.txt
    minikube status > documentation/screenshots/${date_dir}/1-environment/minikube_status_${timestamp}.txt
    
    # kubectl information
    kubectl version --client > documentation/screenshots/${date_dir}/1-environment/kubectl_version_${timestamp}.txt
    
    # Node information
    node --version > documentation/screenshots/${date_dir}/1-environment/node_version_${timestamp}.txt 2>/dev/null
    npm --version > documentation/screenshots/${date_dir}/1-environment/npm_version_${timestamp}.txt 2>/dev/null
    
    # Combined environment details
    show_versions > documentation/screenshots/${date_dir}/1-environment/environment_details_${timestamp}.txt
    
    echo "✅ Environment details captured."
}

# Capture Docker images
capture_docker_images() {
    local date_dir=$(date "+%Y-%m-%d")
    local timestamp=$(date "+%H-%M-%S")
    
    echo "Capturing Docker images..."
    
    # List all Docker images
    docker images > documentation/screenshots/${date_dir}/3-docker/docker_images_${timestamp}.txt
    
    # List Docker containers
    docker ps -a > documentation/screenshots/${date_dir}/3-docker/docker_containers_${timestamp}.txt
    
    # Docker Disk Usage
    docker system df > documentation/screenshots/${date_dir}/3-docker/docker_diskusage_${timestamp}.txt
    
    echo "✅ Docker images captured."
}

# Capture application status
capture_application_status() {
    local date_dir=$(date "+%Y-%m-%d")
    local timestamp=$(date "+%H-%M-%S")
    
    echo "Capturing application status..."
    
    # Application URL
    APP_URL=$(minikube service mern-auth-service -n mern-app --url 2>/dev/null)
    
    if [ -n "$APP_URL" ]; then
        echo "Application URL: $APP_URL" > documentation/screenshots/${date_dir}/2-application/app_url_${timestamp}.txt
        
        # Try to get application status using curl
        curl -s -o /dev/null -w "%{http_code}" "$APP_URL/api/health" > documentation/screenshots/${date_dir}/2-application/app_health_status_${timestamp}.txt
    else
        echo "Application URL not available" > documentation/screenshots/${date_dir}/2-application/app_url_${timestamp}.txt
    fi
    
    echo "✅ Application status captured."
}

# Capture Kubernetes resources
capture_kubernetes_resources() {
    local date_dir=$(date "+%Y-%m-%d")
    local timestamp=$(date "+%H-%M-%S")
    
    echo "Capturing Kubernetes resources..."
    
    # Get all namespaces
    kubectl get namespaces > documentation/screenshots/${date_dir}/4-kubernetes/namespaces_${timestamp}.txt
    
    # Get all resources in the namespace
    kubectl get all -n mern-app -o wide > documentation/screenshots/${date_dir}/4-kubernetes/all_resources_${timestamp}.txt
    
    # Get pods
    kubectl get pods -n mern-app -o wide > documentation/screenshots/${date_dir}/4-kubernetes/pods/pods_${timestamp}.txt
    kubectl describe pods -n mern-app > documentation/screenshots/${date_dir}/4-kubernetes/pods/pods_describe_${timestamp}.txt
    
    # Get services
    kubectl get services -n mern-app -o wide > documentation/screenshots/${date_dir}/4-kubernetes/services/services_${timestamp}.txt
    kubectl describe services -n mern-app > documentation/screenshots/${date_dir}/4-kubernetes/services/services_describe_${timestamp}.txt
    
    # Get deployments
    kubectl get deployments -n mern-app -o wide > documentation/screenshots/${date_dir}/4-kubernetes/deployments/deployments_${timestamp}.txt
    kubectl describe deployments -n mern-app > documentation/screenshots/${date_dir}/4-kubernetes/deployments/deployments_describe_${timestamp}.txt
    
    # Get nodes
    kubectl get nodes -o wide > documentation/screenshots/${date_dir}/4-kubernetes/nodes/nodes_${timestamp}.txt
    kubectl describe nodes > documentation/screenshots/${date_dir}/4-kubernetes/nodes/nodes_describe_${timestamp}.txt
    
    # Get logs
    kubectl logs -l app=mern-auth-app -n mern-app --tail=100 > documentation/screenshots/${date_dir}/4-kubernetes/pods/app_logs_${timestamp}.txt
    kubectl logs -l app=mongodb -n mern-app --tail=100 > documentation/screenshots/${date_dir}/4-kubernetes/pods/mongodb_logs_${timestamp}.txt
    
    echo "✅ Kubernetes resources captured."
}

# Capture GitHub Actions Workflow Status
capture_github_actions_status() {
    local date_dir=$(date "+%Y-%m-%d")
    local timestamp=$(date "+%H-%M-%S")
    
    echo "Documenting GitHub Actions workflow setup..."
    
    # Copy the workflow file
    mkdir -p documentation/screenshots/${date_dir}/5-github-actions
    cp .github/workflows/deploy.yml documentation/screenshots/${date_dir}/5-github-actions/workflow_${timestamp}.yml
    
    # Document the self-hosted runner setup
    echo "GitHub Actions Self-Hosted Runner Setup" > documentation/screenshots/${date_dir}/5-github-actions/runner_setup_${timestamp}.txt
    echo "====================================================" >> documentation/screenshots/${date_dir}/5-github-actions/runner_setup_${timestamp}.txt
    echo "Date: $(date)" >> documentation/screenshots/${date_dir}/5-github-actions/runner_setup_${timestamp}.txt
    echo "The project uses a self-hosted runner to enable GitHub Actions to interact directly with the local Minikube installation." >> documentation/screenshots/${date_dir}/5-github-actions/runner_setup_${timestamp}.txt
    echo "This allows the CI/CD pipeline to build Docker images and deploy to Kubernetes without additional cloud resources." >> documentation/screenshots/${date_dir}/5-github-actions/runner_setup_${timestamp}.txt
    
    echo "✅ GitHub Actions documentation created."
}

# Main execution
load_env
check_prerequisites
check_minikube_running
create_directory_structure
capture_environment
capture_docker_images
capture_application_status
capture_kubernetes_resources
capture_github_actions_status

echo "====================================================="
echo "Documentation screenshots captured successfully!"
echo "Files saved to documentation/screenshots/$(date "+%Y-%m-%d")/"
echo "====================================================="
