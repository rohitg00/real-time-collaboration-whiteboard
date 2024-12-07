#!/bin/bash

# First clean up
echo "Cleaning up previous deployment..."
./scripts/cleanup.sh

# Check minikube
echo "Checking minikube status..."
./scripts/check-minikube.sh

# Apply storage class
echo "Creating storage class..."
kubectl apply -f kubernetes/storage-class.yaml

# Deploy PostgreSQL first
echo "Deploying PostgreSQL..."
kubectl apply -f kubernetes/postgres.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n whiteboard-app --timeout=120s

# Give PostgreSQL time to initialize
echo "Waiting for PostgreSQL to initialize..."
sleep 20

# Initialize database
echo "Initializing database..."
./scripts/init-db.sh

# Deploy Redis
echo "Deploying Redis..."
kubectl apply -f kubernetes/redis.yaml

# Wait for Redis to be ready
echo "Waiting for Redis to be ready..."
kubectl wait --for=condition=ready pod -l app=redis -n whiteboard-app --timeout=120s

# Verify Redis
echo "Verifying Redis..."
./scripts/check-redis.sh

# Create whiteboard storage
echo "Creating whiteboard storage..."
kubectl apply -f kubernetes/whiteboard-storage.yaml

# Wait for storage
echo "Waiting for storage to be ready..."
kubectl wait --for=condition=bound pvc/whiteboard-storage -n whiteboard-app --timeout=60s

# Deploy whiteboard
echo "Deploying whiteboard application..."
kubectl apply -f kubernetes/whiteboard-deployment.yaml

# Wait for deployment
echo "Waiting for whiteboard deployment..."
kubectl rollout status deployment/whiteboard-app -n whiteboard-app --timeout=300s

# Debug if needed
if ! kubectl get pods -n whiteboard-app -l app=whiteboard | grep -q "Running"; then
    echo "Whiteboard pods not running. Running debug..."
    ./scripts/debug-whiteboard.sh
fi

# Deploy monitoring
echo "Deploying monitoring..."
kubectl apply -f kubernetes/monitoring.yaml

echo "Deployment complete! Running final checks..."
kubectl get pods -n whiteboard-app