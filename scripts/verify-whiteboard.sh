#!/bin/bash

echo "Checking whiteboard pods..."
kubectl get pods -n whiteboard-app -l app=whiteboard

echo "Checking whiteboard services..."
kubectl get services -n whiteboard-app

echo "Checking whiteboard endpoints..."
kubectl get endpoints -n whiteboard-app

echo "Checking pod logs..."
FIRST_POD=$(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[0].metadata.name}')
kubectl logs $FIRST_POD -n whiteboard-app

echo "Checking Redis connection..."
kubectl exec -it $FIRST_POD -n whiteboard-app -- nc -zv redis-cluster 6379 