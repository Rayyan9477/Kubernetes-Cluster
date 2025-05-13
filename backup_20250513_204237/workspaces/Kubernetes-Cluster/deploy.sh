#!/bin/bash

# Script to set up and deploy the MERN authentication app to Minikube

# Source common functions
if [ -f "scripts/common.sh" ]; then
    source scripts/common.sh
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "MERN Authentication App - Minikube Deployment Script"
echo "====================================================="

# Main execution
show_versions
check_prerequisites
load_env
start_minikube
build_push_image
deploy_to_kubernetes
verify_deployment
check_logs
get_app_url

echo "====================================================="
echo "Deployment completed successfully!"
echo "====================================================="

# Main execution
show_versions
check_prerequisites
load_env
start_minikube
build_push_image
deploy_to_kubernetes
verify_deployment
check_logs
get_app_url

echo "====================================================="
echo "Deployment completed successfully!"
echo "====================================================="
