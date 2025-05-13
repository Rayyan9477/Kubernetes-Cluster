#!/bin/bash

# Common script to manage environment variables and functions
# -------------------------------------------------------------

# Load environment variables
load_env() {
    if [ -f .env.unified ]; then
        echo "Loading environment variables from .env.unified..."
        export $(grep -v '^#' .env.unified | xargs)
    elif [ -f .env ]; then
        echo "Loading environment variables from .env..."
        export $(grep -v '^#' .env | xargs)
    else
        echo "❌ No environment file found. Please create either:"
        echo "  - .env file (copy from .env.example)"
        echo "  - .env.unified file (copy from .env.example)"
        exit 1
    fi

    # Verify critical environment variables
    verify_env_vars
}

# Verify critical environment variables
verify_env_vars() {
    local missing_vars=false

    # Docker Hub credentials
    if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
        echo "❌ Docker Hub credentials not set in .env file!"
        missing_vars=true
    fi

    # MongoDB configuration
    if [ -z "$MONGODB_USERNAME" ] || [ -z "$MONGODB_PASSWORD" ]; then
        echo "❌ MongoDB credentials not set in .env file!"
        missing_vars=true
    fi

    # Application configuration
    if [ -z "$JWT_SECRET" ]; then
        echo "❌ JWT_SECRET not set in .env file!"
        missing_vars=true
    fi

    if [ "$missing_vars" = true ]; then
        echo "❌ Please set all required environment variables in your .env file."
        exit 1
    fi

    echo "✅ All required environment variables are set."
}

# Display environment versions
show_versions() {
    echo "Environment Details:"
    echo "-------------------"
    echo "Operating System: $(uname -s)"
    echo "OS Version: $(uname -r)"
    echo "Docker Version: $(docker --version)"
    echo "Minikube Version: $(minikube version | head -n 1)"
    echo "kubectl Version: $(kubectl version --client --output=yaml | grep -m 1 gitVersion)"
    echo "Node Version: $(node --version 2>/dev/null || echo 'Not installed')"
    echo "npm Version: $(npm --version 2>/dev/null || echo 'Not installed')"
    echo "====================================================="
}

# Check prerequisites
check_prerequisites() {
    local prerequisites_met=true

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not found. Please install Docker first."
        prerequisites_met=false
    fi

    # Check if Minikube is installed
    if ! command -v minikube &> /dev/null; then
        echo "❌ Minikube not found. Please install Minikube first."
        prerequisites_met=false
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found. Please install kubectl first."
        prerequisites_met=false
    fi

    if [ "$prerequisites_met" = false ]; then
        exit 1
    fi

    echo "✅ All prerequisites met!"
}

# Start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube status &>/dev/null || minikube start --driver=docker
    eval $(minikube docker-env)
    echo "✅ Minikube started successfully!"
}

# Build and push Docker image
build_push_image() {
    echo "Building Docker image..."
    cd app
    docker build -t "${DOCKER_USERNAME}/mern-auth-app:latest" .
    
    echo "Logging into Docker Hub..."
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    
    echo "Pushing image to Docker Hub..."
    docker push "${DOCKER_USERNAME}/mern-auth-app:latest"
    cd ..
    echo "✅ Docker image built and pushed successfully!"
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    echo "Deploying to Kubernetes..."
    
    # Create directory for processed templates
    mkdir -p .k8s-processed
    
    # Process templates
    echo "Processing Kubernetes templates..."
    
    # Process ConfigMap
    envsubst < k8s/configmap.yaml > .k8s-processed/configmap.yaml
    
    # Process Secrets
    cat > .k8s-processed/secrets.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: mern-app-secrets
  namespace: mern-app
type: Opaque
stringData:
  JWT_SECRET: "${JWT_SECRET}"
  MONGODB_USERNAME: "${MONGODB_USERNAME}"
  MONGODB_PASSWORD: "${MONGODB_PASSWORD}"
  MONGO_URI: "${K8S_MONGO_URI}"
EOF
    
    # Process Deployment
    envsubst < k8s/deployment.yaml > .k8s-processed/deployment.yaml
    
    echo "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    
    echo "Creating ConfigMap and Secrets..."
    kubectl apply -f .k8s-processed/configmap.yaml
    kubectl apply -f .k8s-processed/secrets.yaml
    
    echo "Deploying MongoDB..."
    kubectl apply -f k8s/mongodb-deployment.yaml
    kubectl apply -f k8s/mongodb-service.yaml
    
    echo "Deploying application..."
    kubectl apply -f .k8s-processed/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    echo "✅ Deployment completed!"
    
    # Wait for deployments to be ready
    echo "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/mern-auth-app -n mern-app
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n mern-app
}

# Verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    mkdir -p documentation/verification
    
    # Generate timestamp
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Capture Kubernetes status
    echo "Kubernetes Status Report - $TIMESTAMP" > documentation/verification/k8s-status.txt
    echo "===================================================" >> documentation/verification/k8s-status.txt
    
    echo -e "\nPods:" | tee -a documentation/verification/k8s-status.txt
    kubectl get pods -n mern-app -o wide | tee -a documentation/verification/k8s-status.txt
    
    echo -e "\nServices:" | tee -a documentation/verification/k8s-status.txt
    kubectl get services -n mern-app -o wide | tee -a documentation/verification/k8s-status.txt
    
    echo -e "\nDeployments:" | tee -a documentation/verification/k8s-status.txt
    kubectl get deployments -n mern-app -o wide | tee -a documentation/verification/k8s-status.txt
    
    echo -e "\nNodes:" | tee -a documentation/verification/k8s-status.txt
    kubectl get nodes -o wide | tee -a documentation/verification/k8s-status.txt
    
    # Get application URL
    echo -e "\nApplication URL:" | tee -a documentation/verification/k8s-status.txt
    minikube service mern-auth-service -n mern-app --url | tee -a documentation/verification/app-url.txt
    
    echo -e "\nEnvironment Details:" >> documentation/verification/k8s-status.txt
    show_versions >> documentation/verification/k8s-status.txt
}

# Check application logs
check_logs() {
    echo "Checking application logs..."
    
    mkdir -p documentation/verification/logs
    
    echo "MongoDB logs:" | tee documentation/verification/logs/mongodb.log
    kubectl logs -l app=mongodb -n mern-app --tail=50 | tee -a documentation/verification/logs/mongodb.log
    
    echo "Application logs:" | tee documentation/verification/logs/app.log
    kubectl logs -l app=mern-auth-app -n mern-app --tail=50 | tee -a documentation/verification/logs/app.log
}

# Get application URL
get_app_url() {
    echo "Getting application URL..."
    APP_URL=$(minikube service mern-auth-service -n mern-app --url)
    echo "Application is available at: $APP_URL"
    echo "You can also run: minikube service mern-auth-service -n mern-app"
}

# Function to capture screenshots for documentation
capture_screenshots() {
    local timestamp=$(date "+%Y-%m-%d_%H-%M-%S")
    mkdir -p documentation/screenshots/$(date "+%Y-%m-%d")
    
    echo "Capturing environment screenshots..."
    show_versions > documentation/screenshots/$(date "+%Y-%m-%d")/environment_$timestamp.txt
    
    echo "Capturing Kubernetes status..."
    kubectl get pods -n mern-app -o wide > documentation/screenshots/$(date "+%Y-%m-%d")/pods_$timestamp.txt
    kubectl get services -n mern-app -o wide > documentation/screenshots/$(date "+%Y-%m-%d")/services_$timestamp.txt
    kubectl get deployments -n mern-app -o wide > documentation/screenshots/$(date "+%Y-%m-%d")/deployments_$timestamp.txt
    
    echo "Screenshots captured in documentation/screenshots/$(date "+%Y-%m-%d")/"
}

# Clean up resources
cleanup() {
    echo "Cleaning up resources..."
    
    echo "Removing Kubernetes resources..."
    kubectl delete -f k8s/service.yaml
    kubectl delete -f k8s/deployment.yaml
    kubectl delete -f k8s/mongodb-service.yaml
    kubectl delete -f k8s/mongodb-deployment.yaml
    kubectl delete -f k8s/secrets.yaml
    kubectl delete -f k8s/configmap.yaml
    
    echo "Stopping Minikube..."
    minikube stop
    
    echo "✅ Cleanup completed!"
}

# If this script is run directly, show help
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This is a utility script and should be sourced by other scripts, not run directly."
    echo "Usage: source scripts/common.sh"
    exit 1
fi
