#!/bin/bash

# Test script to verify that the application builds and runs correctly
set -e

echo "====================================================="
echo "Testing MERN Authentication App Functionality"
echo "====================================================="

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker first."
  exit 1
fi

# Build and run the application using docker-compose
echo "🔄 Building and starting the application with docker-compose..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check if containers are running
if ! docker-compose ps | grep "Up" > /dev/null; then
  echo "❌ Containers failed to start properly."
  docker-compose logs
  docker-compose down
  exit 1
fi

echo "✅ Application is running successfully!"
echo "📊 Container status:"
docker-compose ps

echo "🔍 Testing backend API health endpoint..."
BACKEND_HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/health)

if [ "$BACKEND_HEALTH_STATUS" == "200" ]; then
  echo "✅ Backend API is healthy (Status: $BACKEND_HEALTH_STATUS)"
else
  echo "❌ Backend API health check failed (Status: $BACKEND_HEALTH_STATUS)"
  echo "Backend logs:"
  docker-compose logs backend
fi

echo "💻 Frontend is available at: http://localhost:3000"
echo "🌐 Backend API is available at: http://localhost:5000"

echo "====================================================="
echo "Test completed. Use the following commands to clean up:"
echo "docker-compose down"
echo "====================================================="
