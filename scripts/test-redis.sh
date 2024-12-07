#!/bin/bash

# Get a whiteboard pod name
POD=$(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[0].metadata.name}')

echo "Testing Redis connection from pod $POD..."
kubectl exec -it $POD -n whiteboard-app -- nc -zv redis-cluster 6379

echo -e "\nChecking Redis cluster status..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret ping

echo -e "\nChecking Redis cluster info..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret info clients 