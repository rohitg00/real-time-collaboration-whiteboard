#!/bin/bash

echo "Checking Redis pod status..."
kubectl get pods -n whiteboard-app -l app=redis

# Get the Redis pod name
REDIS_POD=$(kubectl get pods -n whiteboard-app -l app=redis -o jsonpath='{.items[0].metadata.name}')

echo -e "\nChecking Redis connection..."
kubectl exec -it $REDIS_POD -n whiteboard-app -- redis-cli -a secret ping

echo -e "\nChecking Redis pub/sub channels..."
kubectl exec -it $REDIS_POD -n whiteboard-app -- redis-cli -a secret pubsub channels 