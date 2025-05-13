#!/bin/bash

# Master script to run all operations
set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print fancy header
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}       MERN Auth App - Complete Deployment        ${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1
    echo -e "${RED}❌ Error occurred in script at line $line_number${NC}"
    echo -e "${RED}Exit code: $exit_code${NC}"
    exit $exit_code
}

trap 'handle_error ${LINENO}' ERR

# Initialize variables
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPTS_DIR")"
cd "$PROJECT_ROOT"

# Function to show spinner while waiting
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run a step with spinner and verification
run_step() {
    local message=$1
    local command=$2
    local verify_command=${3:-"true"}
    
    echo -n "🔄 $message..."
    if eval "$command"; then
        if eval "$verify_command"; then
            echo "✅ Done!"
            return 0
        else
            echo "⚠️  Done with warnings!"
            return 1
        fi
    else
        echo "❌ Failed!"
        return 2
    fi
}

# Main execution
print_header

echo "Starting complete deployment process..."

# 1. Check and run setup
echo "📋 Step 1: Running initial setup..."
if [ -f "$SCRIPTS_DIR/setup.sh" ]; then
    run_step "Running setup script" "bash $SCRIPTS_DIR/setup.sh"
else
    echo "❌ Error: setup.sh not found!"
    exit 1
fi

# 2. Load environment variables
echo "🔑 Step 2: Loading environment variables..."
if [ -f "$SCRIPTS_DIR/load-env.sh" ]; then
    source "$SCRIPTS_DIR/load-env.sh"
else
    echo "⚠️ Warning: load-env.sh not found, proceeding with existing environment"
fi

# 3. Deploy application
echo "🚀 Step 3: Deploying application..."
if [ -f "$SCRIPTS_DIR/deploy.sh" ]; then
    run_step "Deploying application" "bash $SCRIPTS_DIR/deploy.sh"
else
    echo "❌ Error: deploy.sh not found!"
    exit 1
fi

# 4. Capture deployment status and screenshots
echo "📸 Step 4: Capturing deployment status..."
if [ -f "$SCRIPTS_DIR/capture-screenshots.sh" ]; then
    run_step "Capturing deployment status" "bash $SCRIPTS_DIR/capture-screenshots.sh"
else
    echo "❌ Error: capture-screenshots.sh not found!"
    exit 1
fi

# 5. Set up GitHub Actions runner (optional)
echo "🤖 Step 5: Setting up GitHub Actions runner..."
if [ -f "$SCRIPTS_DIR/setup-runner.sh" ]; then
    read -p "Do you want to set up the GitHub Actions runner? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_step "Setting up GitHub Actions runner" "bash $SCRIPTS_DIR/setup-runner.sh"
    else
        echo "Skipping GitHub Actions runner setup"
    fi
else
    echo "⚠️ Warning: setup-runner.sh not found, skipping runner setup"
fi

# 6. Verify deployment and show status
echo -e "${BLUE}📊 Deployment Status:${NC}"
echo -e "\n${YELLOW}Kubernetes Resources:${NC}"
echo -e "${GREEN}Pods:${NC}"
kubectl get pods -n mern-app -o wide

echo -e "\n${GREEN}Services:${NC}"
kubectl get services -n mern-app -o wide

echo -e "\n${GREEN}Deployments:${NC}"
kubectl get deployments -n mern-app -o wide

echo -e "\n${YELLOW}Application Logs:${NC}"
echo -e "${GREEN}MongoDB Logs:${NC}"
kubectl logs -l app=mongodb -n mern-app --tail=50

echo -e "\n${GREEN}Backend Logs:${NC}"
kubectl logs -l app=mern-auth-app -n mern-app --tail=50

# 7. Print application URLs and health status
echo -e "\n${BLUE}🌐 Application Access:${NC}"
if command -v minikube &> /dev/null; then
    FRONTEND_URL=$(minikube service mern-auth-service -n mern-app --url)
    BACKEND_URL="${FRONTEND_URL}/api"
    
    echo -e "${GREEN}Frontend URL:${NC} $FRONTEND_URL"
    echo -e "${GREEN}Backend URL:${NC} $BACKEND_URL"
    
    # Check backend health
    echo -e "\n${YELLOW}Health Check:${NC}"
    if curl -s "$BACKEND_URL/health" > /dev/null; then
        echo -e "${GREEN}✅ Backend is healthy${NC}"
    else
        echo -e "${RED}❌ Backend health check failed${NC}"
    fi
else
    echo -e "${RED}⚠️ Warning: Minikube not found, cannot get URLs${NC}"
fi

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}🎉 Deployment process completed!${NC}"
echo -e "${GREEN}Current Status Summary:${NC}"
echo -e "  ${GREEN}✓${NC} MongoDB: $(kubectl get pods -n mern-app -l app=mongodb -o jsonpath='{.items[0].status.phase}')"
echo -e "  ${GREEN}✓${NC} Backend: $(kubectl get pods -n mern-app -l app=mern-auth-app -o jsonpath='{.items[0].status.phase}')"
echo -e "  ${GREEN}✓${NC} Services: Active"

# Get resource usage
echo -e "\n${YELLOW}Resource Usage:${NC}"
echo -e "${BLUE}CPU and Memory Usage:${NC}"
kubectl top pods -n mern-app 2>/dev/null || echo -e "${RED}Metrics not available${NC}"

# Add timestamp
echo -e "\n${BLUE}Deployment completed at:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${BLUE}================================================${NC}"
