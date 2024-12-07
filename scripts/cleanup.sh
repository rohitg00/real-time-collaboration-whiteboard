#!/bin/bash

echo "Cleaning up all resources..."

# Delete namespace to ensure everything is removed
echo "Deleting whiteboard-app namespace..."
kubectl delete namespace whiteboard-app --wait=true

echo "Deleting openstack namespace..."
kubectl delete namespace openstack --wait=true

# Delete PVs (these are cluster-wide resources)
echo "Deleting persistent volumes..."
kubectl delete pv --all

# Delete storage class
echo "Deleting storage class..."
kubectl delete storageclass standard

# Stop any port-forwards
echo "Stopping port forwards..."
pkill -f "kubectl port-forward"

# Wait for cleanup
echo "Waiting for cleanup to complete..."
sleep 30

# Create fresh namespace
echo "Creating fresh whiteboard-app namespace..."
kubectl create namespace whiteboard-app

echo "Cleanup complete!" 