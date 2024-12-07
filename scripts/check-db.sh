#!/bin/bash

POSTGRES_POD=$(kubectl get pods -n whiteboard-app -l app=postgres -o jsonpath='{.items[0].metadata.name}')
WHITEBOARD_POD=$(kubectl get pods -n whiteboard-app -l app=whiteboard -o jsonpath='{.items[0].metadata.name}')

echo "Checking PostgreSQL pod status..."
kubectl get pods -n whiteboard-app -l app=postgres

echo -e "\nChecking PostgreSQL connection from whiteboard pod..."
kubectl exec -it $WHITEBOARD_POD -n whiteboard-app -- nc -zv postgres 5432

echo -e "\nChecking PostgreSQL database..."
kubectl exec -it $POSTGRES_POD -n whiteboard-app -- psql -U spacedeck -d spacedeck -c "\l" 