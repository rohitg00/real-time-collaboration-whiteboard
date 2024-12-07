#!/bin/bash

# Create namespace if it doesn't exist
kubectl create namespace whiteboard-app --dry-run=client -o yaml | kubectl apply -f -

# Ensure Redis cluster is running
echo "Checking Redis cluster..."
if ! kubectl get pods -n whiteboard-app -l app=redis-cluster &>/dev/null; then
    echo "Redis cluster not found. Deploying..."
    kubectl apply -f kubernetes/redis-cluster.yaml
    sleep 10
fi

# Build the whiteboard image
echo "Building whiteboard image..."
docker build -t whiteboard-app:v1 .

# Load the image into minikube
echo "Loading image into minikube..."
minikube image load whiteboard-app:v1

# Apply storage if not exists
echo "Checking storage..."
if ! kubectl get pvc whiteboard-storage -n whiteboard-app &>/dev/null; then
    echo "Creating storage..."
    kubectl apply -f kubernetes/whiteboard-storage.yaml
    sleep 5
fi

# Apply deployments
echo "Deploying whiteboard application..."
kubectl apply -f kubernetes/whiteboard-deployment.yaml
kubectl apply -f kubernetes/monitoring.yaml
kubectl apply -f kubernetes/network-policies.yaml

# Wait for deployment
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/whiteboard-app -n whiteboard-app --timeout=300s

# Verify service endpoints
echo "Verifying service endpoints..."
kubectl get endpoints -n whiteboard-app

# Check pod logs
echo "Checking pod logs..."
kubectl logs -l app=whiteboard -n whiteboard-app --tail=20

echo "Deployment complete!" 