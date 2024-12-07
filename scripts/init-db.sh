#!/bin/bash

POSTGRES_POD=$(kubectl get pods -n whiteboard-app -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "Waiting for PostgreSQL to be ready..."
sleep 10

echo "Initializing PostgreSQL database..."
kubectl exec -it $POSTGRES_POD -n whiteboard-app -- /bin/sh -c "
psql -U spacedeck -d postgres <<EOF
CREATE DATABASE spacedeck;
\\c spacedeck;
CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
EOF
" || true

echo "Verifying database..."
kubectl exec -it $POSTGRES_POD -n whiteboard-app -- psql -U spacedeck -d spacedeck -c "\l"

echo "Database initialized!" 