#!/bin/bash

echo "Waiting for Redis pods to be ready..."
for i in {0..5}; do
    kubectl wait --for=condition=ready pod/redis-cluster-$i -n whiteboard-app --timeout=120s
done

echo "Getting Redis pod IPs..."
REDIS_NODES=""
for i in {0..5}; do
    POD_IP=$(kubectl get pod redis-cluster-$i -n whiteboard-app -o jsonpath='{.status.podIP}')
    REDIS_NODES="$REDIS_NODES $POD_IP:6379"
done

echo "Initializing Redis cluster..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli --cluster create $REDIS_NODES \
    --cluster-replicas 1 \
    --pass secret \
    --cluster-yes

echo "Verifying cluster status..."
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret cluster info