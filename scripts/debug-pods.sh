#!/bin/bash

echo "Checking pod status..."
kubectl get pods -n whiteboard-app

echo -e "\nChecking pod descriptions..."
kubectl describe pods -l app=whiteboard -n whiteboard-app

echo -e "\nChecking pod logs..."
for pod in $(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[*].metadata.name}'); do
    echo -e "\nLogs for $pod:"
    kubectl logs $pod -n whiteboard-app
done

echo -e "\nChecking events..."
kubectl get events -n whiteboard-app --sort-by='.lastTimestamp' 