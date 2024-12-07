#!/bin/bash

echo "Getting whiteboard pod status..."
kubectl get pods -n whiteboard-app -l app=whiteboard

echo -e "\nChecking pod descriptions..."
kubectl describe pods -n whiteboard-app -l app=whiteboard

echo -e "\nChecking pod logs..."
for pod in $(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[*].metadata.name}'); do
    echo -e "\nLogs for $pod:"
    kubectl logs $pod -n whiteboard-app
done

echo -e "\nChecking Redis connectivity..."
WHITEBOARD_POD=$(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$WHITEBOARD_POD" ]; then
    echo "Testing Redis connection from $WHITEBOARD_POD..."
    kubectl exec -it $WHITEBOARD_POD -n whiteboard-app -- nc -zv redis 6379
fi 