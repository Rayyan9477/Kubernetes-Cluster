#!/bin/bash

# Check if .env file exists
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found!"
    echo "Please copy .env.example to .env and update the values."
    exit 1
fi

# Validate required environment variables
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
        echo "Error: $var is not set in .env file"
        exit 1
    fi
done

echo "Environment variables loaded successfully!"
