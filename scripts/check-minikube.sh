#!/bin/bash

echo "Checking minikube status..."
if ! minikube status &>/dev/null; then
    echo "Minikube is not running. Starting..."
    minikube start --memory=8192 --cpus=4 --driver=docker
    
    echo "Waiting for minikube to be ready..."
    sleep 30
    
    echo "Enabling addons..."
    minikube addons enable ingress
    minikube addons enable metrics-server
    
    echo "Verifying status..."
    minikube status
else
    echo "Minikube is running"
    minikube status
fi

echo "Checking kubectl connection..."
kubectl cluster-info 