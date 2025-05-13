#!/bin/bash

# Script to verify GitHub Secrets for the CI/CD workflow
# This is a local verification script to ensure you've set up all required secrets

# Source common functions
if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh"
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "GitHub Secrets Verification"
echo "====================================================="

# Required secrets
REQUIRED_SECRETS=(
    "DOCKER_USERNAME"
    "DOCKER_PASSWORD"
    "MONGODB_USERNAME"
    "MONGODB_PASSWORD"
    "JWT_SECRET"
)

# Load environment variables to check if they're set locally
load_env

# Verify secrets are set in local environment
echo "Checking if secrets are set in local environment..."
MISSING_LOCALLY=false

for secret in "${REQUIRED_SECRETS[@]}"; do
    if [ -z "${!secret}" ]; then
        echo "❌ Secret $secret is not set in your local environment."
        MISSING_LOCALLY=true
    else
        echo "✅ Secret $secret is set in your local environment."
    fi
done

if [ "$MISSING_LOCALLY" = true ]; then
    echo "⚠️ Some secrets are missing in your local environment."
    echo "Please make sure these are set in your .env or .env.unified file."
else
    echo "✅ All required secrets are set in your local environment."
fi

# Reminder to set secrets in GitHub
echo ""
echo "====================================================="
echo "IMPORTANT: GitHub Repository Secrets"
echo "====================================================="
echo "Make sure the following secrets are set in your GitHub repository:"
for secret in "${REQUIRED_SECRETS[@]}"; do
    echo "- $secret"
done
echo ""
echo "To add secrets to your GitHub repository:"
echo "1. Go to your repository in GitHub"
echo "2. Click on 'Settings' tab"
echo "3. In the left sidebar, click on 'Secrets and variables' > 'Actions'"
echo "4. Click on 'New repository secret'"
echo "5. Add each of the secrets listed above"
echo "====================================================="

# GitHub CLI check (optional)
if command -v gh &> /dev/null; then
    echo ""
    echo "GitHub CLI detected! You can use the following commands to set secrets:"
    echo ""
    for secret in "${REQUIRED_SECRETS[@]}"; do
        echo "gh secret set $secret --body \"\${$secret}\" --repo [username]/[repository]"
    done
    echo ""
    echo "Replace [username]/[repository] with your actual GitHub username and repository name."
fi

echo ""
echo "Remember: Never commit sensitive information directly to your repository!"
