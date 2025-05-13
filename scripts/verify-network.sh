#!/bin/bash

# Script to verify network connectivity in Kubernetes cluster
# This script checks if your pods can communicate with each other

# Source common functions
if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh"
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "Kubernetes Network Connectivity Verification"
echo "====================================================="

# Load environment variables
load_env

# Get pod names
APP_POD=$(kubectl get pods -n mern-app -l app=mern-auth-app -o name | head -n 1 | sed 's/pod\///')
MONGO_POD=$(kubectl get pods -n mern-app -l app=mongodb -o name | head -n 1 | sed 's/pod\///')

if [ -z "$APP_POD" ] || [ -z "$MONGO_POD" ]; then
    echo "❌ Cannot find pods. Make sure they are running!"
    exit 1
fi

echo "Application Pod: $APP_POD"
echo "MongoDB Pod: $MONGO_POD"

# Check if network policies are supported
echo "Checking if NetworkPolicy is supported in your cluster..."
if kubectl api-resources | grep -q networkpolicies; then
    echo "✅ NetworkPolicy is supported in your cluster."
else
    echo "⚠️ NetworkPolicy is not supported in your cluster. Standard cluster communication will be used."
fi

# Check network policies
echo "Checking NetworkPolicies in the namespace..."
kubectl get networkpolicies -n mern-app

# Test connectivity from app pod to MongoDB service
echo "Testing connectivity from app to MongoDB..."
kubectl exec -n mern-app $APP_POD -- curl -s -m 5 mongodb-service:27017
CONN_RESULT=$?

if [ $CONN_RESULT -eq 28 ] || [ $CONN_RESULT -eq 52 ]; then
    echo "✅ Connection attempt to MongoDB reached the server (timeout/connection refused is expected since we're not using a MongoDB client)"
elif [ $CONN_RESULT -eq 7 ]; then
    echo "❌ Connection to MongoDB failed! Network policy might be blocking traffic."
    echo "Checking network policy configuration..."
    kubectl describe networkpolicy allow-app-to-mongodb -n mern-app
else
    echo "Connection test result: $CONN_RESULT"
fi

# Verify DNS resolution
echo "Verifying DNS resolution..."
kubectl exec -n mern-app $APP_POD -- nslookup mongodb-service.mern-app.svc.cluster.local 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ DNS resolution for MongoDB service is working."
else
    echo "❌ DNS resolution failed. This might cause connection issues."
fi

# Test MongoDB connectivity using application's mechanism
echo "Testing application's MongoDB connection..."
kubectl exec -n mern-app $APP_POD -- curl -s http://localhost:${PORT}/api/health | grep -i database
if [ $? -eq 0 ]; then
    echo "✅ Application can connect to MongoDB according to health check."
else
    echo "❌ Application health check indicates issues with MongoDB connection."
fi

# Create network verification report
mkdir -p documentation/verification
echo "Network Connectivity Report - $(date "+%Y-%m-%d %H:%M:%S")" > documentation/verification/network-status.txt
echo "====================================================" >> documentation/verification/network-status.txt
echo "Application Pod: $APP_POD" >> documentation/verification/network-status.txt
echo "MongoDB Pod: $MONGO_POD" >> documentation/verification/network-status.txt
echo "" >> documentation/verification/network-status.txt
echo "Network Policies:" >> documentation/verification/network-status.txt
kubectl get networkpolicies -n mern-app -o wide >> documentation/verification/network-status.txt

echo "Network connectivity report saved to documentation/verification/network-status.txt"
