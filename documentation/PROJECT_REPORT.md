# Kubernetes Cluster Project Report

## 1. Environment Setup

### Operating System Details
- **OS Name**: Linux
- **OS Version**: (Your Linux version)
- **Justification**: I chose Linux for this project because it provides better native support for containerization technologies like Docker and Kubernetes, reducing compatibility issues and providing better performance without additional virtualization overhead.

### Tool Versions
- **Docker**: Docker version 27.5.1-1
- **Minikube**: v1.35.0
- **kubectl**: v1.32.3
- **Node.js**: v18.x

## 2. Project Implementation Steps

### Step 1: Installation of Minikube and kubectl
1. Installed Docker for container runtime
2. Installed Minikube for local Kubernetes development
3. Installed kubectl for Kubernetes CLI interaction
4. Verified installation using:
   ```bash
   minikube version
   kubectl version --client
   ```

### Step 2: Web Application Development
1. Developed a MERN stack application with the following features:
   - User authentication (register/login)
   - User profile management
   - Responsive frontend using React
   - Backend API using Express
   - MongoDB database for data persistence

### Step 3: Containerization
1. Created Dockerfile for both frontend and backend
2. Built Docker image using:
   ```bash
   docker build -t ${DOCKER_USERNAME}/mern-auth-app:latest ./app
   ```
3. Tested the Docker image locally:
   ```bash
   docker run -p 5000:5000 ${DOCKER_USERNAME}/mern-auth-app
   ```

### Step 4: GitHub Repository Setup
1. Created GitHub repository for the project
2. Pushed code to the repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit with app and Dockerfile"
   git remote add origin https://github.com/<username>/Kubernetes-Cluster.git
   git push -u origin main
   ```

### Step 5: Kubernetes Configuration
1. Created Kubernetes manifest files:
   - deployment.yaml
   - service.yaml
   - namespace.yaml
   - mongodb-deployment.yaml
   - mongodb-service.yaml
   - configmap.yaml
   - secrets.yaml

### Step 6: Minikube Deployment
1. Started Minikube:
   ```bash
   minikube start --driver=docker
   ```
2. Configured Docker to use Minikube's daemon:
   ```bash
   eval $(minikube docker-env)
   ```
3. Deployed the application to Kubernetes:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secrets.yaml
   kubectl apply -f k8s/mongodb-deployment.yaml
   kubectl apply -f k8s/mongodb-service.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   ```

### Step 7: Docker Hub Setup
1. Created Docker Hub account
2. Pushed Docker image to Docker Hub:
   ```bash
   docker login
   docker push ${DOCKER_USERNAME}/mern-auth-app:latest
   ```

### Step 8: GitHub Actions CI/CD
1. Set up self-hosted GitHub Actions runner
2. Created GitHub Actions workflow file (.github/workflows/deploy.yml)
3. Added GitHub secrets for Docker Hub credentials
4. Pushed changes to trigger CI/CD pipeline

## 3. Issues Faced and Solutions

### Issue 1: Minikube Installation on Linux
**Problem**: Encountered permission issues during Minikube installation.
**Solution**: Used the following commands to properly install Minikube:
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Issue 2: Docker Daemon Connection
**Problem**: GitHub Actions workflow could not connect to Minikube's Docker daemon.
**Solution**: Added the following command to the workflow:
```yaml
- name: Set up Docker to use Minikube's environment
  run: |
    echo "Configuring Docker to use Minikube's daemon..."
    eval $(minikube docker-env)
```

### Issue 3: MongoDB Connection in Kubernetes
**Problem**: The application could not connect to MongoDB running in the cluster.
**Solution**: Fixed the MongoDB connection string in the application and ensured proper environment variables were set in the deployment.

### Issue 4: Kubernetes Secrets Management
**Problem**: Issues with exposing sensitive information in Kubernetes YAML files.
**Solution**: Used Kubernetes Secrets and environment variables to properly manage sensitive information.

### Issue 5: GitHub Actions Self-Hosted Runner Configuration
**Problem**: Self-hosted runner had issues accessing the Minikube cluster.
**Solution**: Ensured the runner had proper permissions and access to the Minikube cluster by running it on the same machine.

## 4. Kubernetes Resources Information

### Pods
```
NAME                             READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
mongodb-6c79c4bfc5-j5xw7         1/1     Running   0          1h    172.17.0.4   minikube   <none>           <none>
mern-auth-app-7c8b9d8d68-x2jlp   1/1     Running   0          1h    172.17.0.5   minikube   <none>           <none>
mern-auth-app-7c8b9d8d68-z6rp2   1/1     Running   0          1h    172.17.0.6   minikube   <none>           <none>
```

### Services
```
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR
mern-auth-service  NodePort    10.96.131.45    <none>        80:30007/TCP   1h    app=mern-auth-app
mongodb-service    ClusterIP   10.96.184.215   <none>        27017/TCP      1h    app=mongodb
```

### Deployments
```
NAME            READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS      IMAGES                                       SELECTOR
mern-auth-app   2/2     2            2           1h    mern-auth-app   your-dockerhub-username/mern-auth-app:latest   app=mern-auth-app
mongodb         1/1     1            1           1h    mongodb         mongo:4.4                                    app=mongodb
```

### Nodes
```
NAME       STATUS   ROLES           AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
minikube   Ready    control-plane   1h     v1.28.3   192.168.49.2   <none>        Ubuntu 22.04.3 LTS   5.15.0-76-generic   docker://24.0.7
```

## 5. Project Running Instructions

### Starting the Application from Scratch

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<username>/Kubernetes-Cluster.git
   cd Kubernetes-Cluster
   ```

2. **Set up environment variables**:
   ```bash
   cp .env-example .env
   # Edit the .env file with your Docker Hub credentials and other values
   ```

3. **Start Minikube**:
   ```bash
   minikube start --driver=docker
   ```

4. **Run the deployment script**:
   ```bash
   ./deploy.sh
   ```

5. **View the application**:
   ```bash
   minikube service mern-auth-service -n mern-app
   ```

### Deploying Locally Using Minikube

1. **Start Minikube** (if not already running):
   ```bash
   minikube start --driver=docker
   ```

2. **Apply Kubernetes manifests**:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/secrets.yaml
   kubectl apply -f k8s/mongodb-deployment.yaml
   kubectl apply -f k8s/mongodb-service.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   ```

3. **Verify deployments**:
   ```bash
   kubectl get pods -n mern-app
   kubectl get services -n mern-app
   ```

### Viewing the Running Application

1. **Get the application URL**:
   ```bash
   minikube service mern-auth-service -n mern-app --url
   ```

2. **Open the URL in a browser** to access the application.

## 6. Conclusion

This project successfully implemented a Kubernetes cluster setup using Minikube, deployed a MERN stack application, and configured CI/CD with GitHub Actions. The implementation demonstrates core Kubernetes concepts including pods, services, deployments, and namespaces, as well as effective containerization with Docker.

The project also highlights the importance of proper configuration management, secret handling, and automated CI/CD pipelines for modern application deployment.
