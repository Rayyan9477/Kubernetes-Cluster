#!/bin/bash

# Print fancy header
print_header() {
    echo "================================================"
    echo "       MERN Auth App - Setup Script              "
    echo "================================================"
}

# Check for required tools
check_prerequisites() {
    echo "Checking prerequisites..."
    local missing_tools=()

    # Check for Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi

    # Check for docker-compose
    if ! command -v docker-compose &> /dev/null; then
        missing_tools+=("docker-compose")
    fi

    # Check for kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi

    # Check for minikube
    if ! command -v minikube &> /dev/null; then
        missing_tools+=("minikube")
    fi

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "❌ Missing required tools: ${missing_tools[*]}"
        echo "Please install these tools and try again."
        exit 1
    fi

    echo "✅ All prerequisites checked"
}

# Setup environment variables
setup_env() {
    if [ ! -f .env ]; then
        echo "Creating .env file from template..."
        cp .env.example .env
        echo "Please update the .env file with your actual values"
        exit 1
    fi

    echo "✅ Environment file exists"
}

# Main execution
print_header
check_prerequisites
setup_env

echo "✅ Setup completed successfully!"
echo "Next steps:"
echo "1. Update the .env file with your actual values"
echo "2. Run './scripts/deploy.sh' to deploy the application"
