# Kubernetes Cluster Setup with MERN Authentication App

This project demonstrates how to set up a Kubernetes cluster using Minikube and deploy a MERN stack authentication application with automated CI/CD using GitHub Actions. The project includes a complete authentication system with user registration, login, and profile management.

## Environment Details

- **Operating System**: Linux
- **Docker**: Docker version 27.5.1-1
- **Minikube**: v1.35.0
- **Kubectl**: v1.32.3

## Project Overview

This project implements a full-stack MERN application with authentication capabilities, deployed on a local Kubernetes cluster using Minikube. Key features include:

1. **Kubernetes Deployment** - Deploy a containerized application to a local Kubernetes cluster
2. **CI/CD with GitHub Actions** - Automate the build and deployment process
3. **MongoDB Database** - Using a containerized MongoDB instance
4. **Authentication System** - Complete user registration and login functionality
5. **RESTful API** - Well-structured backend API
6. **React Frontend** - Modern, responsive user interface

## Prerequisites

1. Docker installed and running
2. Minikube installed
3. kubectl installed
4. GitHub account
5. Docker Hub account
6. Node.js and npm installed (for local development)

## Getting Started

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd Kubernetes-Cluster
```

### Step 2: Set Up Environment Variables

Create a `.env` file in the repository root based on the provided `.env.example`:

```bash
cp .env.example .env
```

Then edit the `.env` file to add your specific configuration values.

For detailed environment configuration information, see [Environment Configuration](./documentation/ENVIRONMENT.md).

Add these secrets to your GitHub repository:
1. Go to Settings > Secrets and Variables > Actions
2. Add the following secrets:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - `JWT_SECRET`
   - `MONGODB_USERNAME`
   - `MONGODB_PASSWORD`

### Step 3: Local Development

1. Start MongoDB (if running locally):

   ```bash
   docker run -d -p 27017:27017 mongo:4.4
   ```

2. Install dependencies and run the application:

   ```bash
   # Install backend dependencies
   cd app/backend
   npm install

   # Install frontend dependencies
   cd ../frontend
   npm install

   # Start both frontend and backend
   cd ..
   docker-compose up
   ```

### Step 4: Deployment with Minikube

1. Start Minikube:

   ```bash
   minikube start --driver=docker
   ```

2. Use Minikube's Docker daemon:

   ```bash
   eval $(minikube docker-env)
   ```

3. Run the deployment script:
```bash
./deploy.sh
```

The script will:
- Check prerequisites
- Display environment versions
- Build and push Docker image
- Deploy to Kubernetes
- Verify the deployment
- Display the application URL

### Step 5: Accessing the Application

1. Get the application URL:
```bash
minikube service mern-auth-service -n mern-app --url
```

### Step 6: CI/CD with GitHub Actions

1. Set up a self-hosted runner on your machine:
   - Go to your GitHub repository
   - Navigate to Settings > Actions > Runners
   - Click "New self-hosted runner" and follow the instructions

2. Push changes to GitHub to trigger automated deployment:
```bash
git add .
git commit -m "Update application"
git push origin main
```
```

2. Open the URL in your browser to access the application.

## Project Structure

```
.
├── README.md
├── app/                   # MERN Application
│   ├── Dockerfile
│   ├── package.json
│   ├── backend/           # Node.js Express Backend
│   └── frontend/          # React Frontend
├── k8s/                   # Kubernetes Manifests
│   ├── deployment.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── .github/workflows/     # CI/CD Pipelines
│   └── deploy.yml
├── docker-compose.yml     # For local development
└── deploy.sh              # Helper script for local deployment
```

## Prerequisites

1. Docker installed
2. Minikube installed
3. kubectl installed
4. GitHub account
5. Docker Hub account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/Kubernetes-Cluster.git
cd Kubernetes-Cluster
```

### 2. Set up GitHub Secrets

Add the following secrets to your GitHub repository:
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password

### 3. Set up a Self-Hosted GitHub Actions Runner

Follow the instructions in your GitHub repository settings to set up a self-hosted runner on your local machine.

### 4. Local Development

You can use Docker Compose for local development:

```bash
docker-compose up
```

This will start the application and MongoDB in development mode.

### 5. Manual Deployment to Minikube

Run the deployment script:

```bash
./deploy.sh
```

This script will:
- Start Minikube if it's not running
- Configure Docker to use Minikube's daemon
- Build the Docker image
- Create the Kubernetes namespace if it doesn't exist
- Deploy the application to Minikube
- Display the service URL

### 6. CI/CD Deployment

Push changes to the main branch to trigger the GitHub Actions workflow:

```bash
git add .
git commit -m "Update application"
git push origin main
```

The GitHub Actions workflow will:
- Build the Docker image
- Push it to Docker Hub
- Deploy to Minikube

## Accessing the Application

After deployment, you can access the application using:

```bash
minikube service mern-auth-service -n mern-app --url
```

## Kubernetes Commands

### View Resources

```bash
# View pods
kubectl get pods -n mern-app -o wide

# View services
kubectl get services -n mern-app -o wide

# View deployments
kubectl get deployments -n mern-app -o wide

# View nodes
kubectl get nodes -o wide
```

### Debugging

```bash
# View pod logs
kubectl logs <pod-name> -n mern-app

# Execute command in pod
kubectl exec -it <pod-name> -n mern-app -- /bin/bash

# Describe pod
kubectl describe pod <pod-name> -n mern-app
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**:
   - Make sure your Docker Hub credentials are correct
   - Check that you've properly tagged and pushed the image

2. **Pod Pending State**:
   - Ensure Minikube has enough resources
   - Check for PersistentVolumeClaims that might be pending

3. **Connection Refused**:
   - Verify the service is running: `kubectl get svc -n mern-app`
   - Check if pods are running: `kubectl get pods -n mern-app`

4. **Authentication Issues with MongoDB**:
   - Verify MongoDB is running: `kubectl get pods -n mern-app | grep mongodb`
   - Check MongoDB logs: `kubectl logs <mongodb-pod-name> -n mern-app`

5. **GitHub Actions Runner Issues**:
   - Ensure runner is online in GitHub repository settings
   - Check runner logs on your local machine

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Project Structure

```
├── app/                   # MERN Authentication application
│   ├── backend/           # Node.js Express backend
│   ├── frontend/          # React frontend
│   └── Dockerfile         # Docker configuration for the app
├── k8s/                   # Kubernetes configuration files
│   ├── deployment.yaml    # App deployment configuration
│   ├── service.yaml       # App service configuration
│   ├── mongodb-deployment.yaml # MongoDB deployment configuration
│   ├── mongodb-service.yaml    # MongoDB service configuration
│   └── namespace.yaml     # Namespace configuration
├── .github/
│   └── workflows/
│       └── deploy.yml     # GitHub Actions workflow for CI/CD
└── README.md              # This documentation file
```

## Prerequisites

- Docker
- Minikube
- kubectl
- A DockerHub account
- GitHub account with a self-hosted runner configured

## Step-by-Step Instructions

### 1. Install Prerequisites

#### Docker
```bash
# Check if Docker is installed
docker --version

# If not installed, install Docker
# For Ubuntu/Debian:
sudo apt update
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
```

#### Minikube
```bash
# Check if Minikube is installed
minikube version

# If not installed, install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

#### kubectl
```bash
# Check if kubectl is installed
kubectl version --client

# If not installed, install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 2. Setup Minikube

Start Minikube:
```bash
minikube start
```

Verify Minikube status:
```bash
minikube status
```

### 3. Configure Docker to use Minikube's Docker daemon

```bash
eval $(minikube docker-env)
```

### 4. Clone the Repository

```bash
git clone https://github.com/your-username/Kubernetes-Cluster.git
cd Kubernetes-Cluster
```

### 5. Build the Docker Image

```bash
docker build -t your-dockerhub-username/mern-auth-app:latest ./app
```

### 6. Push the Image to Docker Hub

```bash
docker login
docker push your-dockerhub-username/mern-auth-app:latest
```

### 7. Create Kubernetes Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

### 8. Deploy the Application to Kubernetes

```bash
# Deploy MongoDB
kubectl apply -f k8s/mongodb-deployment.yaml
kubectl apply -f k8s/mongodb-service.yaml

# Deploy the MERN app
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 9. Verify Deployments and Services

```bash
# Check deployments
kubectl get deployments -n mern-app -o wide

# Check pods
kubectl get pods -n mern-app -o wide

# Check services
kubectl get services -n mern-app -o wide

# Check nodes
kubectl get nodes -o wide
```

### 10. Access the Application

```bash
minikube service mern-auth-service -n mern-app
```

### 11. Setup GitHub Actions

1. Add the following secrets to your GitHub repository:
   - `DOCKER_USERNAME`: Your Docker Hub username
   - `DOCKER_PASSWORD`: Your Docker Hub password or access token

2. Set up a self-hosted runner on your local machine by following the instructions provided by GitHub.

3. Push your code to GitHub to trigger the CI/CD workflow.

## Troubleshooting

### Issue 1: Minikube fails to start

**Solution:** Ensure your system has virtualization enabled in BIOS and that you have sufficient resources. Try with different drivers:

```bash
minikube start --driver=docker
```

### Issue 2: Docker build fails

**Solution:** Check your Dockerfile for errors and ensure all dependencies are correctly specified.

### Issue 3: Kubernetes deployments pending

**Solution:** Check for resource constraints:

```bash
kubectl describe pod <pod-name> -n mern-app
```

### Issue 4: Cannot access the service

**Solution:** Ensure the service is properly exposed:

```bash
kubectl get services -n mern-app
minikube service mern-auth-service -n mern-app --url
```

### Issue 5: MongoDB connection issues

**Solution:** Verify that the MongoDB service is correctly deployed and the connection string in the app is correct:

```bash
kubectl logs <app-pod-name> -n mern-app
kubectl describe service mongodb-service -n mern-app
```

## Architectural Overview

### Components

1. **Frontend**: React application with Redux for state management
2. **Backend**: Node.js/Express REST API
3. **Database**: MongoDB
4. **Container**: Docker
5. **Container Orchestration**: Kubernetes (Minikube)
6. **CI/CD**: GitHub Actions

### Kubernetes Resources

1. **Namespace**: Isolates the application resources
2. **Deployments**: 
   - MERN application deployment
   - MongoDB deployment
3. **Services**:
   - Application service (NodePort)
   - MongoDB service (ClusterIP)

## Monitoring and Management

### Useful Commands

1. **Check pod status**:
```bash
kubectl get pods -n mern-app -o wide
```

2. **Check logs**:
```bash
kubectl logs deployment/mern-auth-app -n mern-app
```

3. **Scale deployment**:
```bash
kubectl scale deployment mern-auth-app -n mern-app --replicas=3
```

4. **Update image**:
```bash
kubectl set image deployment/mern-auth-app mern-auth-app=${DOCKER_USERNAME}/mern-auth-app:latest -n mern-app
```

## Security Considerations

1. Secrets management using Kubernetes secrets
2. HTTPS/TLS configuration
3. Network policies
4. Role-Based Access Control (RBAC)
5. Container security best practices

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.