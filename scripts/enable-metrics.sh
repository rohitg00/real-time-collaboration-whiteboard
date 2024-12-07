#!/bin/bash

# Enable metrics-server addon
minikube addons enable metrics-server

# Wait for metrics-server to be ready
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

echo "Metrics API enabled and ready" 