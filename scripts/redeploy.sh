#!/bin/bash

echo "Cleaning up whiteboard deployment..."
kubectl delete deployment whiteboard-app -n whiteboard-app --ignore-not-found
kubectl delete pods -l app=whiteboard -n whiteboard-app --force --grace-period=0 --ignore-not-found

echo "Cleaning up whiteboard storage..."
kubectl delete pvc whiteboard-storage -n whiteboard-app --ignore-not-found

echo "Waiting for cleanup..."
sleep 10

echo "Applying storage class..."
kubectl apply -f kubernetes/storage-class.yaml

echo "Creating whiteboard storage..."
kubectl apply -f kubernetes/whiteboard-storage.yaml

echo "Waiting for storage to be ready..."
kubectl wait --for=condition=bound pvc/whiteboard-storage -n whiteboard-app --timeout=60s

echo "Redeploying application..."
./scripts/deploy-whiteboard.sh

echo "Checking deployment status..."
./scripts/debug-pods.sh 