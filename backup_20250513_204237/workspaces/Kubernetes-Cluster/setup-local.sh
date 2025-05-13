#!/bin/bash

# Script to set up a local development environment

# Source common functions
if [ -f "scripts/common.sh" ]; then
    source scripts/common.sh
else
    echo "❌ Common script not found!"
    exit 1
fi

echo "====================================================="
echo "🔧 Kubernetes Cluster - Local Development Environment Setup"
echo "====================================================="

# Load environment variables
load_env

# Setup options
echo "Select setup type:"
echo "1) Development environment (direct Node.js)"
echo "2) Docker Compose development environment"
echo "3) Minikube environment"
read -p "Select an option (1-3): " setup_type

case $setup_type in
    1)
        # Direct Node.js setup
        # Override to use local configuration
        export NODE_ENV=development
        export FRONTEND_URL=$LOCAL_FRONTEND_URL
        export VITE_BACKEND_URL=$LOCAL_BACKEND_URL
        export MONGO_URI=$LOCAL_MONGO_URI
        
        echo "🔄 Setting up MongoDB using Docker..."
        # Check if container already exists
        if [ "$(docker ps -a -q -f name=mern-mongodb)" ]; then
            echo "MongoDB container already exists. Starting..."
            docker start mern-mongodb
        else
            docker run -d \
              --name mern-mongodb \
              -p ${MONGODB_PORT}:27017 \
              -e MONGO_INITDB_ROOT_USERNAME=${MONGODB_USERNAME} \
              -e MONGO_INITDB_ROOT_PASSWORD=${MONGODB_PASSWORD} \
              -e MONGO_INITDB_DATABASE=${MONGODB_DATABASE} \
              mongo:4.4
        fi
        
        echo "📦 Installing backend dependencies..."
        cd app/backend
        npm install
        
        echo "📦 Installing frontend dependencies..."
        cd ../frontend
        npm install
        
        echo "====================================================="
        echo "✅ Development setup completed successfully!"
        echo ""
        echo "To start the backend:"
        echo "cd app/backend && npm run dev"
        echo ""
        echo "To start the frontend:"
        echo "cd app/frontend && npm run dev"
        echo "====================================================="
        ;;
    2)
        # Docker Compose setup
        echo "🐳 Setting up using Docker Compose..."
        
        # Create .env file for docker-compose
        cat > app/.env <<EOF
NODE_ENV=development
PORT=${PORT}
MONGO_URI=mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@mongodb:${MONGODB_PORT}/${MONGODB_DATABASE}?authSource=admin
JWT_SECRET=${JWT_SECRET}
FRONTEND_URL=${LOCAL_FRONTEND_URL}
VITE_BACKEND_URL=${LOCAL_BACKEND_URL}
MONGODB_USERNAME=${MONGODB_USERNAME}
MONGODB_PASSWORD=${MONGODB_PASSWORD}
MONGODB_DATABASE=${MONGODB_DATABASE}
EOF
        
        # Go to app directory and start docker-compose
        cd app
        
        echo "🔄 Starting Docker Compose services..."
        docker-compose down # Stop any running containers
        docker-compose up -d # Start in detached mode
        
        echo "====================================================="
        echo "✅ Docker Compose setup completed successfully!"
        echo ""
        echo "The application should be running at:"
        echo "Frontend: ${LOCAL_FRONTEND_URL}"
        echo "Backend: ${LOCAL_BACKEND_URL}"
        echo ""
        echo "To view logs: docker-compose logs -f"
        echo "To stop: docker-compose down"
        echo "====================================================="
        ;;
    3)
        # Minikube setup
        echo "☸️  Setting up Minikube environment..."
        
        # Check and start Minikube
        show_versions
        check_prerequisites
        start_minikube
        
        # Deploy to Minikube
        build_push_image
        deploy_to_kubernetes
        verify_deployment
        get_app_url
        
        echo "====================================================="
        echo "✅ Minikube setup completed successfully!"
        echo ""
        echo "Your application should be running in Minikube."
        echo "To verify: ./verify.sh"
        echo "To access: minikube service mern-auth-service -n mern-app"
        echo "====================================================="
        ;;
    *)
        echo "❌ Invalid option. Exiting..."
        exit 1
        ;;
esac

exit 0================================================"
