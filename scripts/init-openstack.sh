#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo "Installing dependencies..."
brew install python@3.9
brew install minikube
brew install kubectl
brew install docker

# Ensure Python and pip are in PATH
export PATH="/usr/local/opt/python@3.9/bin:$PATH"

# Install OpenStack client
echo "Installing OpenStack client..."
pip3 install --user python-openstackclient python-heatclient python-neutronclient

# Add pip packages to PATH
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
PIP_BIN_PATH="$HOME/Library/Python/$PYTHON_VERSION/bin"
export PATH="$PIP_BIN_PATH:$PATH"

# Update PATH in shell config files without sourcing
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "Library/Python/$PYTHON_VERSION/bin" "$HOME/.zshrc"; then
        echo "export PATH=\"$PIP_BIN_PATH:\$PATH\"" >> "$HOME/.zshrc"
        echo "Added pip bin path to .zshrc"
    fi
fi

if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "Library/Python/$PYTHON_VERSION/bin" "$HOME/.bashrc"; then
        echo "export PATH=\"$PIP_BIN_PATH:\$PATH\"" >> "$HOME/.bashrc"
        echo "Added pip bin path to .bashrc"
    fi
fi

# Verify OpenStack client installation
if ! command -v openstack &> /dev/null; then
    echo "Error: OpenStack client installation failed"
    echo "Please run these commands in a new terminal and try again:"
    echo "export PATH=\"$PIP_BIN_PATH:\$PATH\""
    echo "./scripts/init-openstack.sh"
    exit 1
fi

# Set OpenStack environment variables
export OS_USERNAME="admin"
export OS_PASSWORD="secret"
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_AUTH_URL="http://localhost:5000/v3"
export OS_IDENTITY_API_VERSION=3

# Start Docker if not running
if ! docker info &> /dev/null; then
    echo "Starting Docker..."
    open -a Docker
    # Wait for Docker to start
    sleep 20
fi

# Start minikube if not running
if ! minikube status &> /dev/null; then
    echo "Starting minikube..."
    minikube start --memory=8192 --cpus=4 --driver=docker
fi

# Deploy OpenStack using kolla-kubernetes
echo "Deploying OpenStack..."
kubectl create namespace openstack
kubectl apply -f openstack/kolla-config.yaml

# Wait for OpenStack services to be ready
echo "Waiting for OpenStack services..."
kubectl wait --for=condition=ready pod -l app=keystone -n openstack --timeout=300s

# Initialize OpenStack services
echo "Initializing OpenStack services..."
kubectl exec -it -n openstack $(kubectl get pods -n openstack -l app=keystone -o jsonpath='{.items[0].metadata.name}') -- \
  keystone-manage bootstrap \
  --bootstrap-password secret \
  --bootstrap-admin-url http://localhost:5000/v3/ \
  --bootstrap-internal-url http://localhost:5000/v3/ \
  --bootstrap-public-url http://localhost:5000/v3/ \
  --bootstrap-region-id RegionOne

# Wait for keystone to be ready
echo "Waiting for Keystone to be ready..."
sleep 10

# Verify OpenStack client can connect
echo "Verifying OpenStack connection..."
openstack endpoint list

# Initialize Redis cluster
echo "Initializing Redis cluster..."
kubectl apply -f kubernetes/redis-cluster.yaml

# Create initial networks
echo "Creating networks..."
openstack network create internal-net
openstack subnet create internal-subnet --network internal-net --subnet-range 192.168.1.0/24

# Deploy whiteboard application
echo "Deploying whiteboard stack..."
openstack stack create -t openstack/heat-template.yaml whiteboard-stack 

# Apply additional configurations
echo "Applying additional configurations..."
kubectl apply -f kubernetes/monitoring.yaml
kubectl apply -f kubernetes/user-management.yaml
kubectl apply -f kubernetes/state-sync.yaml
kubectl apply -f kubernetes/network-policies.yaml

# Wait for all components to be ready
echo "Waiting for components to be ready..."
kubectl wait --for=condition=ready pod -l app=prometheus -n whiteboard-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n whiteboard-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=user-management -n whiteboard-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=state-sync -n whiteboard-app --timeout=300s

# Verify deployment
echo "Verifying deployment..."
kubectl get pods -n whiteboard-app

echo "Setup complete! Run ./scripts/verify-openstack.sh to verify the installation."