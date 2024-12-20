#!/bin/bash

set -euo pipefail

# Set variables
CLUSTER_NAME="todo-app-cluster"
NAMESPACE="todo-app"
SERVICE_NAME="todo-app"
APP_HELM_CHART_PATH="./helm/todo-app"
MIGRATIONS_HELM_CHART_PATH="./helm/migrations"
DB_HELM_CHART_PATH="./helm/postgres"
APP_IMAGE_NAME="todo-app:latest"
MIGRATIONS_IMAGE_NAME="todo-app-migrations:latest"

# Create k3d cluster
if k3d cluster list | grep -q "^${CLUSTER_NAME} "; then
  echo "Cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
  echo "Creating k3d cluster: $CLUSTER_NAME..."
  k3d cluster create $CLUSTER_NAME --servers 1 --agents 3
fi

# Switch kubectl context to the new cluster
echo "Switching kubectl context to k3d cluster..."
k3d kubeconfig merge ${CLUSTER_NAME}
kubectl config use-context "k3d-${CLUSTER_NAME}"

# Verify correct context
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ ${CURRENT_CONTEXT} != "k3d-${CLUSTER_NAME}" ]]; then
    echo "Error: Failed to switch to k3d cluster context"
    exit 1
fi

# Build and push migrations Docker image
echo "Building Docker image: $MIGRATIONS_IMAGE_NAME..."
docker build -t $MIGRATIONS_IMAGE_NAME -f ./migrations/Dockerfile .

echo "Pushing Docker image to cluster..."
k3d image import $MIGRATIONS_IMAGE_NAME -c $CLUSTER_NAME

# Build and push app Docker image
echo "Building Docker image: $APP_IMAGE_NAME..."
docker build -t $APP_IMAGE_NAME -f ./src/Dockerfile .

echo "Pushing Docker image to cluster..."
k3d image import $APP_IMAGE_NAME -c $CLUSTER_NAME

# Create namespace
echo "Creating namespace: $NAMESPACE..."
kubectl create namespace $NAMESPACE || echo "Namespace $NAMESPACE already exists."

# Deploy db Helm chart
echo "Deploying db Helm chart..."
helm upgrade --install postgres $DB_HELM_CHART_PATH \
  --namespace $NAMESPACE \
  --set podsIps="10.42.0.0/16" \
  --wait \
  --debug

# Deploy app db migrations Helm chart
echo "Deploying migrations Helm chart..."
helm upgrade --install migrations $MIGRATIONS_HELM_CHART_PATH --namespace $NAMESPACE --wait --debug

# Deploy app Helm chart
echo "Deploying app Helm chart..."
helm upgrade --install todo-app $APP_HELM_CHART_PATH --namespace $NAMESPACE --wait --debug

# Port forward for local testing (optional)
echo "Port-forwarding the service for local access..."
kubectl port-forward svc/$SERVICE_NAME 8080:80 -n $NAMESPACE &
PORT_FORWARD_PID=$!

echo "Deployment completed. Access your app at http://localhost:8080"
echo "Port-forward PID: $PORT_FORWARD_PID"
