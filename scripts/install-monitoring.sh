#!/bin/bash

# Add Prometheus repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus Operator
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Wait for CRDs to be ready
kubectl wait --for condition=established --timeout=60s crd/servicemonitors.monitoring.coreos.com

echo "Prometheus Operator installed successfully" 