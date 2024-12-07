#!/bin/bash

# Check if OpenStack client is installed
if ! command -v openstack &> /dev/null; then
    echo "Error: OpenStack client not found. Please run init-openstack.sh first"
    exit 1
fi

# Source OpenStack environment variables if not set
if [ -z "$OS_USERNAME" ]; then
    export OS_USERNAME="admin"
    export OS_PASSWORD="secret"
    export OS_PROJECT_NAME="admin"
    export OS_USER_DOMAIN_NAME="Default"
    export OS_PROJECT_DOMAIN_NAME="Default"
    export OS_AUTH_URL="http://localhost:5000/v3"
    export OS_IDENTITY_API_VERSION=3
fi

# Check OpenStack services
echo "Checking OpenStack services..."
openstack service list

# Check endpoints
echo "Checking endpoints..."
openstack endpoint list

# Check networks
echo "Checking networks..."
openstack network list

# Check compute services
echo "Checking compute services..."
openstack compute service list

# Check running instances
echo "Checking instances..."
openstack server list

# Check Heat stacks
echo "Checking Heat stacks..."
openstack stack list

# Check Kubernetes components
echo "Checking Kubernetes components..."
kubectl get pods --all-namespaces 