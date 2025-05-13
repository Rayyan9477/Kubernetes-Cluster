#!/bin/bash

# Script to deploy MERN Auth app to Kubernetes
set -e

# Load environment variables
load_env() {
    if [ ! -f .env ]; then
        echo "❌ Error: .env file not found!"
        echo "Please run './scripts/setup.sh' first"
        exit 1
    fi

    # Export all variables from .env
    export $(cat .env | grep -v '^#' | xargs)

    # Validate required variables
    required_vars=(
        "MONGODB_USERNAME"
        "MONGODB_PASSWORD"
        "JWT_SECRET"
        "NODE_ENV"
        "PORT"
        "FRONTEND_URL"
        "VITE_BACKEND_URL"
        "DOCKER_USERNAME"
        "DOCKER_PASSWORD"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "❌ Error: $var is not set in .env file"
            exit 1
        fi
    done

    echo "✅ Environment variables loaded"
}

# Build and push Docker images
build_images() {
    echo "Building and pushing Docker images..."
    
    # Login to Docker Hub
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

    # Build and push backend
    docker build -t "$DOCKER_USERNAME/mern-auth-backend:latest" ./app/backend
    docker push "$DOCKER_USERNAME/mern-auth-backend:latest"

    # Build and push frontend
    docker build -t "$DOCKER_USERNAME/mern-auth-frontend:latest" ./app/frontend
    docker push "$DOCKER_USERNAME/mern-auth-frontend:latest"

    echo "✅ Docker images built and pushed"
}

# Deploy to Kubernetes
deploy_kubernetes() {
    echo "Deploying to Kubernetes..."

    # Start Minikube if not running
    if ! minikube status > /dev/null 2>&1; then
        echo "Starting Minikube..."
        minikube start --driver=docker
    fi

    # Create namespace
    kubectl apply -f k8s/namespace.yaml

    # Deploy ConfigMap and Secrets
    envsubst < k8s/configmap.yaml | kubectl apply -f -
    envsubst < k8s/secrets.yaml | kubectl apply -f -

    # Deploy MongoDB
    kubectl apply -f k8s/mongodb-deployment.yaml
    kubectl apply -f k8s/mongodb-service.yaml

    # Deploy application
    envsubst < k8s/deployment.yaml | kubectl apply -f -
    kubectl apply -f k8s/service.yaml

    echo "✅ Kubernetes deployment completed"
}

# Verify deployment
verify_deployment() {
    echo "Verifying deployment..."

    # Wait for deployments
    kubectl wait --namespace=mern-app --for=condition=available --timeout=300s deployment/mern-auth-app
    kubectl wait --namespace=mern-app --for=condition=available --timeout=300s deployment/mongodb

    # Get deployment status
    echo "Deployment Status:"
    kubectl get pods,svc,deployments -n mern-app

    # Get application URL
    echo "Application URL:"
    minikube service mern-auth-service -n mern-app --url

    echo "✅ Deployment verified"
}

# Main execution
echo "Starting deployment process..."
load_env
build_images
deploy_kubernetes
verify_deployment

echo "✅ Deployment completed successfully!"
