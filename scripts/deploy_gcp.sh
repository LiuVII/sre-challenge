#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE="todo-app"
APP_HELM_CHART_PATH="./helm/todo-app"
MIGRATIONS_HELM_CHART_PATH="./helm/migrations"
DB_HELM_CHART_PATH="./helm/postgres"
TAG="1.0.2"
APP_IMAGE_NAME="todo-app:${TAG}"
MIGRATIONS_IMAGE_NAME="todo-app-migrations:${TAG}"
PROJECT_ID="sre-challenge-b71f132d"
REGION="europe-west1"
IMAGE_REPOSITORY="${REGION}-docker.pkg.dev/${PROJECT_ID}/sre-challenge-repository"

# Staging specific config
CLUSTER_NAME="sre-challenge-cluster-s"
IP_ADDRESS="34.54.49.46"
IP_NAME="sre-challenge-ip-s"

export TAG
export IMAGE_REPOSITORY
export IP_ADDRESS
export IP_NAME

# Get GKE credentials
echo "Getting GKE cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Set current context to namespace
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE}

# # Build and push Docker image
# echo "Building and pushing Docker images..."
# gcloud auth configure-docker ${REGION}-docker.pkg.dev
# # docker build -t ${APP_IMAGE_NAME} -f src/Dockerfile .
# docker tag "${APP_IMAGE_NAME}" "${IMAGE_REPOSITORY}/${APP_IMAGE_NAME}"
# docker push "${IMAGE_REPOSITORY}/${APP_IMAGE_NAME}"

# # docker build -t ${MIGRATIONS_IMAGE_NAME} -f ./migrations/Dockerfile . .
# docker tag "${MIGRATIONS_IMAGE_NAME}" "${IMAGE_REPOSITORY}/${MIGRATIONS_IMAGE_NAME}"
# docker push "${IMAGE_REPOSITORY}/${MIGRATIONS_IMAGE_NAME}"

# Install/upgrade PostgreSQL chart
echo "Deploying PostgreSQL..."
helm upgrade --install postgres ${DB_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${DB_HELM_CHART_PATH}/values.yaml \
  --wait \
  --debug

# Install/upgrade app db migrations chart
echo "Deploying migrations..."
helm upgrade --install migrations ${MIGRATIONS_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${MIGRATIONS_HELM_CHART_PATH}/values.yaml \
  --set image.repository="${IMAGE_REPOSITORY}/todo-app-migrations" \
  --set image.tag="${TAG}" \
  --set image.pullPolicy="IfNotPresent" \
  --wait \
  --debug

# Create temporary values file from template
envsubst < "${APP_HELM_CHART_PATH}/values-gcp.yaml" > /tmp/values-gcp.yaml

# Install/upgrade Todo app chart
echo "Deploying Todo app..."
helm upgrade --install todo-app ${APP_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values "${APP_HELM_CHART_PATH}/values.yaml" \
  --values /tmp/values-gcp.yaml \
  --wait \
  --debug

# Clean up
rm /tmp/values-gcp.yaml

echo "Deployment completed!"
