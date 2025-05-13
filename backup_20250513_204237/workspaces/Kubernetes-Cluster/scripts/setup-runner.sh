#!/bin/bash

# Script to set up GitHub Actions self-hosted runner
# This script should be run on the machine where Minikube is running

# Source common functions
if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh"
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "GitHub Actions Self-Hosted Runner Setup"
echo "====================================================="

# Check prerequisites
check_prerequisites

# Load environment variables
load_env

# Configuration
RUNNER_VERSION="2.309.0"
RUNNER_DIR="${HOME}/actions-runner"

# Create runner directory
mkdir -p ${RUNNER_DIR}
cd ${RUNNER_DIR}

# Download runner package
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract runner package
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Configure dependencies
./bin/installdependencies.sh

echo "====================================================="
echo "Runner downloaded and dependencies installed!"
echo "To configure your runner, you need to:"
echo "1. Go to your GitHub repository"
echo "2. Navigate to Settings > Actions > Runners"
echo "3. Click 'New self-hosted runner'"
echo "4. Copy the configuration token"
echo "====================================================="

# Prompt for GitHub details and token
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name: " GITHUB_REPO
read -p "Enter your GitHub Actions runner token: " RUNNER_TOKEN

if [ -z "${RUNNER_TOKEN}" ] || [ -z "${GITHUB_USERNAME}" ] || [ -z "${GITHUB_REPO}" ]; then
    echo "❌ GitHub details or token cannot be empty!"
    exit 1
fi

# Configure the runner
echo "Configuring GitHub Actions runner..."
./config.sh --url https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO} --token ${RUNNER_TOKEN} --name "minikube-runner" --labels "minikube,kubernetes,self-hosted" --work _work

# Ask if runner should be installed as a service
read -p "Do you want to install the runner as a service? (y/n): " INSTALL_SERVICE

if [[ "$INSTALL_SERVICE" =~ ^[Yy]$ ]]; then
    # Install as a service
    echo "Installing runner as a service..."
    sudo ./svc.sh install
    
    # Start the service
    echo "Starting the runner service..."
    sudo ./svc.sh start
    
    # Check service status
    echo "Checking runner service status..."
    sudo ./svc.sh status
    
    # Configure runner user permissions
    echo "Setting up runner permissions for Docker and Kubernetes..."
    RUNNER_USER=$(id -u -n)
    
    # Add runner to docker group for Docker access
    sudo usermod -aG docker $RUNNER_USER
    
    # Copy Kubernetes config to runner user home
    mkdir -p ~/.kube
    cp ~/.kube/config ~/.kube/config || echo "No Kubernetes config found. Make sure to set it up manually."
    chmod 600 ~/.kube/config || true
    
    # Test permissions
    echo "Testing Docker permissions..."
    docker ps > /dev/null 2>&1 && echo "✅ Docker access verified" || echo "❌ Docker access failed"
    
    echo "Testing Kubernetes permissions..."
    kubectl get nodes > /dev/null 2>&1 && echo "✅ Kubernetes access verified" || echo "❌ Kubernetes access failed"
else
    echo "To start the runner manually, run: ./run.sh"
fi

echo "====================================================="
echo "GitHub Actions self-hosted runner setup complete!"
echo "Runner is installed at: ${RUNNER_DIR}"
echo "====================================================="
