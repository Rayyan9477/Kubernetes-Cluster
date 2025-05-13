#!/bin/bash

# Script to verify the Kubernetes setup and generate status report

# Source common functions
if [ -f "scripts/common.sh" ]; then
    source scripts/common.sh
else
    echo "❌ Common script not found!"
    exit 1
fi

echo "====================================================="
echo "Kubernetes Verification and Status Report Generator"
echo "====================================================="

# Main execution
check_prerequisites
load_env
verify_deployment
check_logs
get_app_url
capture_screenshots

echo "====================================================="
echo "Verification completed successfully!"
echo "Report generated at documentation/verification/k8s-status.txt"
echo "====================================================="
