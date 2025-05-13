#!/bin/bash

# Script to monitor MongoDB initialization in Kubernetes
# This script checks if MongoDB is properly initialized and running

# Source common functions
if [ -f "$(dirname "$0")/common.sh" ]; then
    source "$(dirname "$0")/common.sh"
else
    echo "❌ Common script not found!"
    exit 1
fi

# Display header
echo "====================================================="
echo "MongoDB Initialization Monitor"
echo "====================================================="

# Load environment variables
load_env

# Check if MongoDB pod is running
echo "Checking MongoDB pod status..."
kubectl get pods -n mern-app -l app=mongodb

# Wait for MongoDB pod to be ready
echo "Waiting for MongoDB pod to be ready..."
kubectl wait --namespace=mern-app --for=condition=ready pod -l app=mongodb --timeout=300s
if [ $? -ne 0 ]; then
    echo "❌ MongoDB pod did not become ready in time!"
    echo "Checking pod events and logs for troubleshooting:"
    
    # Get pod name
    MONGO_POD=$(kubectl get pods -n mern-app -l app=mongodb -o name | head -n 1)
    
    if [ -n "$MONGO_POD" ]; then
        echo "Pod events:"
        kubectl describe $MONGO_POD -n mern-app
        
        echo "Pod logs:"
        kubectl logs $MONGO_POD -n mern-app
    else
        echo "No MongoDB pod found!"
    fi
    
    exit 1
fi

echo "✅ MongoDB pod is ready!"

# Test MongoDB connection
echo "Testing MongoDB connection..."
MONGO_POD=$(kubectl get pods -n mern-app -l app=mongodb -o name | head -n 1 | sed 's/pod\///')

# Execute test command in MongoDB pod
kubectl exec -n mern-app $MONGO_POD -- mongosh \
    --username $MONGODB_USERNAME \
    --password $MONGODB_PASSWORD \
    --authenticationDatabase admin \
    --eval "db.adminCommand('ping')" \
    $MONGODB_DATABASE

if [ $? -ne 0 ]; then
    echo "❌ Failed to connect to MongoDB!"
    exit 1
else
    echo "✅ Successfully connected to MongoDB!"
fi

# Check if users collection exists
echo "Checking if users collection exists..."
kubectl exec -n mern-app $MONGO_POD -- mongosh \
    --username $MONGODB_USERNAME \
    --password $MONGODB_PASSWORD \
    --authenticationDatabase admin \
    --eval "db.getCollectionNames().includes('users')" \
    $MONGODB_DATABASE

echo "====================================================="
echo "MongoDB Status Report"
echo "====================================================="
echo "Pod Name: $MONGO_POD"
echo "Database: $MONGODB_DATABASE"
echo "====================================================="

# Save MongoDB status report
mkdir -p documentation/verification
echo "MongoDB Status Report - $(date "+%Y-%m-%d %H:%M:%S")" > documentation/verification/mongodb-status.txt
echo "====================================================" >> documentation/verification/mongodb-status.txt
echo "Pod Name: $MONGO_POD" >> documentation/verification/mongodb-status.txt
echo "Database: $MONGODB_DATABASE" >> documentation/verification/mongodb-status.txt
echo "====================================================" >> documentation/verification/mongodb-status.txt
kubectl get pods -n mern-app -l app=mongodb -o wide >> documentation/verification/mongodb-status.txt

echo "MongoDB status report saved to documentation/verification/mongodb-status.txt"
