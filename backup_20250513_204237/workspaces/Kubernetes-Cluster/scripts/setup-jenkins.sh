#!/bin/bash
# setup-jenkins.sh - Sets up Jenkins for Kubernetes-Cluster CI/CD

# Source common functions
source scripts/common.sh

# Load environment variables
load_env

# Print welcome banner
echo "====================================================="
echo "🔧 Jenkins Setup for Kubernetes Cluster CI/CD"
echo "====================================================="

# Verify minikube is running
if ! minikube status | grep -q "host: Running"; then
    echo "🚀 Starting Minikube..."
    start_minikube
fi

# Create Jenkins namespace
echo "Creating Jenkins namespace..."
kubectl create namespace jenkins || true

# Create volume for Jenkins data
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/jenkins"
EOF

# Create PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

# Create Jenkins deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jenkins
  namespace: jenkins
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      securityContext:
        fsGroup: 1000
      containers:
      - name: jenkins
        image: jenkins/jenkins:lts
        ports:
        - containerPort: 8080
          name: httpport
        - containerPort: 50000
          name: jnlpport
        volumeMounts:
        - name: jenkins-home
          mountPath: /var/jenkins_home
        resources:
          limits:
            cpu: "1"
            memory: "2Gi"
          requests:
            cpu: "500m"
            memory: "1Gi"
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 60
          timeoutSeconds: 5
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 120
          timeoutSeconds: 5
      volumes:
      - name: jenkins-home
        persistentVolumeClaim:
          claimName: jenkins-pvc
EOF

# Create Jenkins service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: jenkins
  namespace: jenkins
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
    name: http
  - port: 50000
    targetPort: 50000
    name: jnlp
  selector:
    app: jenkins
EOF

# Wait for Jenkins to be ready
echo "Waiting for Jenkins deployment to be ready..."
kubectl rollout status deployment/jenkins -n jenkins

# Get admin password
echo "Getting Jenkins admin password..."
echo "Please wait while Jenkins starts up. This may take a few minutes..."
sleep 60
POD_NAME=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath="{.items[0].metadata.name}")

# Monitor pod readiness
echo "Waiting for Jenkins pod to be ready..."
until kubectl get pod $POD_NAME -n jenkins -o jsonpath='{.status.containerStatuses[0].ready}' | grep -q "true"; do
    echo "Waiting for Jenkins pod to be ready..."
    sleep 10
done

JENKINS_PASSWORD=$(kubectl exec $POD_NAME -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword)

# Display access information
echo "====================================================="
echo "✅ Jenkins setup complete!"
echo "====================================================="
echo "Access Jenkins at: http://$(minikube ip):30080"
echo "Initial Admin Password: $JENKINS_PASSWORD"
echo "====================================================="
echo ""
echo "Next steps:"
echo "1. Access Jenkins using the URL and password above"
echo "2. Complete the setup wizard and install suggested plugins"
echo "3. Create a Pipeline job using the Jenkinsfile in your repository"
echo "4. Configure GitHub webhook to trigger builds automatically"
echo "====================================================="

# Create a Jenkinsfile in the repository root
cat > Jenkinsfile <<EOF
pipeline {
    agent any
    
    environment {
        DOCKER_USERNAME = credentials('docker-username')
        DOCKER_PASSWORD = credentials('docker-password')
        IMAGE_NAME = 'mern-auth-app'
        K8S_NAMESPACE = 'mern-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t \${DOCKER_USERNAME}/\${IMAGE_NAME}:latest ./app'
            }
        }
        
        stage('Push Docker Image') {
            steps {
                sh 'docker login -u \${DOCKER_USERNAME} -p \${DOCKER_PASSWORD}'
                sh 'docker push \${DOCKER_USERNAME}/\${IMAGE_NAME}:latest'
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                sh './deploy.sh'
            }
        }
        
        stage('Verify Deployment') {
            steps {
                sh './verify.sh'
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
EOF

echo "Jenkinsfile created in repository root."
echo "====================================================="
