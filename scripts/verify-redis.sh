#!/bin/bash

echo "Checking Redis cluster status..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret cluster info

echo "Checking Redis cluster nodes..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret cluster nodes

echo "Checking Redis cluster slots..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret cluster slots 