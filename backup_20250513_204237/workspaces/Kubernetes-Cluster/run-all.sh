#!/bin/bash

# Master script to run the entire workflow from setup to verification

# Source common functions
if [ -f "scripts/common.sh" ]; then
    source scripts/common.sh
else
    echo "❌ Common script not found!"
    exit 1
fi

echo "====================================================="
echo "🚀 Kubernetes Cluster - Complete Deployment Workflow"
echo "====================================================="

# Check for .env.unified file
if [ ! -f .env.unified ] && [ ! -f .env ]; then
    echo "No environment file found. Creating from template..."
    cp .env.unified.example .env.unified
    
    echo "📝 Please configure your environment variables:"
    echo "1) Edit manually later"
    echo "2) Configure now (interactive)"
    read -p "Select an option (1-2): " env_option
    
    if [ "$env_option" == "2" ]; then
        # Interactive environment configuration
        read -p "Enter your Docker Hub username: " docker_username
        read -sp "Enter your Docker Hub password: " docker_password
        echo ""
        read -p "Enter your GitHub username: " github_username
        read -p "Enter your GitHub repository name [Kubernetes-Cluster]: " github_repo
        github_repo=${github_repo:-Kubernetes-Cluster}
        
        # Update .env.unified with user input
        sed -i "s/DOCKER_USERNAME=your_docker_username/DOCKER_USERNAME=${docker_username}/g" .env.unified
        sed -i "s/DOCKER_PASSWORD=your_docker_password/DOCKER_PASSWORD=${docker_password}/g" .env.unified
        sed -i "s/GITHUB_USERNAME=your_github_username/GITHUB_USERNAME=${github_username}/g" .env.unified
        sed -i "s/GITHUB_REPO=Kubernetes-Cluster/GITHUB_REPO=${github_repo}/g" .env.unified
        
        echo "✅ Environment variables updated!"
    else
        echo "Please edit .env.unified with your configuration before continuing."
        exit 1
    fi
fi

# Load environment variables
load_env

# Setup options
echo "====================================================="
echo "Deployment Options"
echo "====================================================="
echo "1) Full local deployment (Minikube only)"
echo "2) Setup GitHub Actions runner and deploy"
echo "3) Setup Jenkins and integrate with Kubernetes"
echo "4) All-in-one: Minikube + GitHub Actions + Jenkins"
echo "5) Exit"

read -p "Select an option (1-5): " deploy_option

case $deploy_option in
    1)
        # Full local deployment
        echo "🔧 Starting local deployment with Minikube..."
        show_versions
        check_prerequisites
        start_minikube
        build_push_image
        deploy_to_kubernetes
        verify_deployment
        check_logs
        get_app_url
        
        # Ask if user wants to capture documentation
        read -p "Do you want to capture deployment documentation? (y/n): " capture_docs
        if [[ "$capture_docs" =~ ^[Yy]$ ]]; then
            echo "📸 Capturing deployment documentation..."
            ./scripts/capture-screenshots.sh
        fi
        ;;
    2)
        # GitHub Actions runner setup and deploy
        echo "🔧 Setting up GitHub Actions runner..."
        ./scripts/setup-runner.sh
        
        echo "To complete the GitHub Actions deployment:"
        echo "1. Push your code to GitHub"
        echo "2. The workflow will automatically deploy your application"
        echo "3. You can monitor the progress in GitHub Actions tab"
        ;;
    3)
        # Jenkins setup
        echo "🔧 Setting up Jenkins..."
        ./scripts/setup-jenkins.sh
        
        echo "Jenkins is now set up and accessible."
        echo "1. Access Jenkins at: http://$(minikube ip):30080"
        echo "2. Configure a pipeline using the Jenkinsfile in the repository"
        echo "3. Set up GitHub webhook for automatic builds"
        ;;
    4)
        # Complete setup
        echo "🔧 Starting complete setup: Minikube + GitHub Actions + Jenkins"
        
        # Setup Minikube and deploy application
        show_versions
        check_prerequisites
        start_minikube
        build_push_image
        deploy_to_kubernetes
        verify_deployment
        
        # Setup GitHub Actions runner
        echo "🔧 Setting up GitHub Actions runner..."
        ./scripts/setup-runner.sh
        
        # Setup Jenkins
        echo "🔧 Setting up Jenkins..."
        ./scripts/setup-jenkins.sh
        
        # Display access information
        get_app_url
        echo "Jenkins is accessible at: http://$(minikube ip):30080"
        
        # Capture documentation
        echo "📸 Capturing deployment documentation..."
        ./scripts/capture-screenshots.sh
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "❌ Invalid option. Exiting..."
        exit 1
        ;;
esac

echo "====================================================="
echo "✅ Deployment process completed!"
echo "====================================================="

# Final instructions
if [ "$deploy_option" == "1" ]; then
    echo "Your application should now be accessible at the URL shown above."
    echo "To clean up resources later, run: ./cleanup.sh"
fi

exit 0
