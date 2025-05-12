#!/bin/bash

# Script to set up and deploy the MERN authentication app to Minikube

# Display header
echo "====================================================="
echo "MERN Authentication App - Minikube Deployment Script"
echo "====================================================="

# Function to display environment versions
show_versions() {
    echo "Environment Details:"
    echo "-------------------"
    echo "Operating System: $(uname -s)"
    echo "OS Version: $(uname -r)"
    echo "Docker Version: $(docker --version)"
    echo "Minikube Version: $(minikube version | head -n 1)"
    echo "kubectl Version: $(kubectl version --client --output=json | grep gitVersion | head -n 1)"
    echo "====================================================="
}

# Function to check prerequisites
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

# Function to start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube start --driver=docker
    eval $(minikube docker-env)
    echo "✅ Minikube started successfully!"
}

# Function to build and push Docker image
build_push_image() {
    # Load environment variables
    if [ -f .env ]; then
        export $(cat .env | grep -v '^#' | xargs)
    else
        echo "❌ .env file not found!"
        exit 1
    fi

    # Verify Docker Hub credentials
    if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
        echo "❌ Docker Hub credentials not set in .env file!"
        exit 1
    fi

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

# Function to deploy to Kubernetes
deploy_to_kubernetes() {
    echo "Deploying to Kubernetes..."
    
    echo "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    
    echo "Creating ConfigMap and Secrets..."
    kubectl apply -f k8s/configmap.yaml
    kubectl apply -f k8s/secrets.yaml
    
    echo "Deploying MongoDB..."
    kubectl apply -f k8s/mongodb-deployment.yaml
    kubectl apply -f k8s/mongodb-service.yaml
    
    echo "Deploying application..."
    envsubst < k8s/deployment.yaml | kubectl apply -f -
    kubectl apply -f k8s/service.yaml
    
    echo "✅ Deployment completed!"
    
    # Wait for deployments to be ready
    echo "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/mern-auth-app -n mern-app
    kubectl wait --for=condition=available --timeout=300s deployment/mongodb -n mern-app
}

# Function to verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    echo "Pods:"
    kubectl get pods -n mern-app -o wide
    echo "Services:"
    kubectl get services -n mern-app -o wide
    echo "Deployments:"
    kubectl get deployments -n mern-app -o wide
}

# Function to check application logs
check_logs() {
    echo "Checking application logs..."
    echo "MongoDB logs:"
    kubectl logs -l app=mongodb -n mern-app --tail=50
    
    echo "Application logs:"
    kubectl logs -l app=mern-auth-app -n mern-app --tail=50
}

# Function to get application URL
get_app_url() {
    echo "Getting application URL..."
    minikube service mern-auth-service -n mern-app --url
}

# Main execution
show_versions
check_prerequisites
start_minikube
build_push_image
deploy_to_kubernetes
verify_deployment
check_logs
get_app_url
