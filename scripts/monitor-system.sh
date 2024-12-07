#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== System Monitoring Script ===${NC}"

# Check cluster resources
echo -e "\n${GREEN}Checking Cluster Resources:${NC}"
if ! kubectl top nodes &>/dev/null; then
    echo "Enabling metrics-server..."
    minikube addons enable metrics-server
    sleep 30  # Wait for metrics to be available
fi
echo "CPU Usage:"
kubectl top nodes || echo "Metrics not yet available"
echo -e "\nMemory Usage:"
kubectl top pods --all-namespaces || echo "Metrics not yet available"

# Check Redis Cluster Health
echo -e "\n${GREEN}Redis Cluster Health:${NC}"
kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret info replication

# Check Whiteboard Application Metrics
echo -e "\n${GREEN}Whiteboard Application Status:${NC}"
kubectl get hpa whiteboard-scaler -n whiteboard-app

# Check Prometheus Metrics
echo -e "\n${GREEN}Prometheus Metrics:${NC}"
if ! kubectl get pods -n whiteboard-app -l app=prometheus &>/dev/null; then
    echo "Prometheus not found. Deploying monitoring stack..."
    kubectl apply -f kubernetes/monitoring.yaml
    sleep 30
fi
PROM_POD=$(kubectl get pods -n whiteboard-app -l app=prometheus -o jsonpath='{.items[0].metadata.name}')
if [ -z "$PROM_POD" ]; then
    echo "Waiting for Prometheus pod to be ready..."
else
    kubectl port-forward $PROM_POD 9090:9090 -n whiteboard-app &
    PF_PID=$!
    sleep 5

    # Query some metrics
    curl -s "http://localhost:9090/api/v1/query" --data-urlencode 'query=container_memory_usage_bytes{namespace="whiteboard-app"}'
    curl -s "http://localhost:9090/api/v1/query" --data-urlencode 'query=container_cpu_usage_seconds_total{namespace="whiteboard-app"}'

    kill $PF_PID 2>/dev/null
fi

# Check Network Policies
echo -e "\n${GREEN}Network Policies:${NC}"
kubectl get networkpolicies -n whiteboard-app

# Check Persistent Volumes
echo -e "\n${GREEN}Persistent Volumes:${NC}"
kubectl get pv,pvc -n whiteboard-app

# Check Logs for Errors
echo -e "\n${GREEN}Recent Error Logs:${NC}"
kubectl logs -n whiteboard-app -l app=whiteboard --tail=50 | grep -i error

# Check Service Endpoints
echo -e "\n${GREEN}Service Endpoints:${NC}"
kubectl get endpoints -n whiteboard-app

# System Recommendations
echo -e "\n${YELLOW}System Recommendations:${NC}"
# Check if whiteboard deployment exists
if ! kubectl get deployment whiteboard-app -n whiteboard-app &>/dev/null; then
    echo -e "${RED}Warning: Whiteboard deployment not found. Deploying...${NC}"
    kubectl apply -f kubernetes/whiteboard-deployment.yaml
fi

# Check if HPA is working
if ! kubectl get hpa whiteboard-scaler -n whiteboard-app &>/dev/null; then
    echo -e "${YELLOW}Creating HorizontalPodAutoscaler...${NC}"
    kubectl apply -f kubernetes/monitoring.yaml
fi

# Check Redis memory usage
REDIS_MEMORY=$(kubectl exec -it redis-cluster-0 -n whiteboard-app -- redis-cli -a secret info memory | grep "used_memory_human")
echo "Redis Memory Usage: $REDIS_MEMORY"

# Summary
echo -e "\n${YELLOW}Summary:${NC}"
echo "- Whiteboard Pods: $(kubectl get pods -n whiteboard-app -l app=whiteboard -o json | jq '.items | length')"
echo "- Redis Nodes: $(kubectl get pods -n whiteboard-app -l app=redis-cluster -o json | jq '.items | length')"
echo "- Monitoring Status: $(kubectl get pods -n whiteboard-app -l app=prometheus -o jsonpath='{.status.phase}')" 