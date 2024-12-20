#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE="todo-app"
APP_HELM_CHART_PATH="./helm/todo-app"
MIGRATIONS_HELM_CHART_PATH="./helm/migrations"
DB_HELM_CHART_PATH="./helm/postgres"
PROJECT_ID="sre-challenge-b71f132d"
REGION="europe-west1"
IMAGE_REPOSITORY="${REGION}-docker.pkg.dev/${PROJECT_ID}/sre-challenge-repository"

# Staging specific config
CLUSTER_NAME="sre-challenge-cluster-s"
IP_ADDRESS="34.54.49.46"
IP_NAME="sre-challenge-ip-s"
GCP_SA_EMAIL="sre-challenge-workload-s@sre-challenge-b71f132d.iam.gserviceaccount.com"
CLUSTER_PODS_IPS="10.11.0.0/16"

# Parse command line arguments
BUILD_PUSH=false
TAG=""

usage() {
  echo "Usage: $0 -t <tag> [-b]"
  echo "  -t: Version tag for deployment (e.g., 1.0.0)"
  echo "  -b: Build and push images to registry (optional)"
  exit 1
}

while getopts "t:b" opt; do
  case ${opt} in
    t )
      # Validate tag format
      if [[ ! $OPTARG =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Tag must be in semantic versioning format (e.g., 1.0.0)"
        usage
      fi
      TAG=$OPTARG
      ;;
    b )
      BUILD_PUSH=true
      ;;
    \? )
      usage
      ;;
  esac
done

# Check if tag is empty or just contains whitespace
if [ -z "${TAG// }" ]; then
  echo "Error: Tag parameter (-t) is required and cannot be empty"
  usage
fi

export TAG
export IMAGE_REPOSITORY
export IP_ADDRESS
export IP_NAME
export GCP_SA_EMAIL

# Get GKE credentials
echo "Getting GKE cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Set current context to namespace
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE}

if [ "$BUILD_PUSH" = true ]; then
  echo "Authenticating with GCP Artifact Registry..."
  gcloud auth configure-docker ${REGION}-docker.pkg.dev

  # Build and push Docker image
  echo "Building and pushing Docker images..."
  
  docker build -t "${IMAGE_REPOSITORY}/todo-app:${TAG}" -f src/Dockerfile .
  docker build -t "${IMAGE_REPOSITORY}/todo-app-migrations:${TAG}" -f ./migrations/Dockerfile .

  docker push "${IMAGE_REPOSITORY}/todo-app:${TAG}"
  docker push "${IMAGE_REPOSITORY}/todo-app-migrations:${TAG}"
fi

# Install/upgrade PostgreSQL chart
echo "Deploying PostgreSQL..."
helm upgrade --install postgres ${DB_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${DB_HELM_CHART_PATH}/values.yaml \
  --set workloadIdentityServiceAccount="$GCP_SA_EMAIL" \
  --set podsIps="$CLUSTER_PODS_IPS" \
  --wait \
  --debug

# Install/upgrade app db migrations chart
echo "Cleaning up previous migration job..."
kubectl delete job migrations -n ${NAMESPACE} --ignore-not-found=true

echo "Deploying migrations..."
helm upgrade --install migrations ${MIGRATIONS_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${MIGRATIONS_HELM_CHART_PATH}/values.yaml \
  --set image.repository="${IMAGE_REPOSITORY}/todo-app-migrations" \
  --set image.tag="${TAG}" \
  --set image.pullPolicy="IfNotPresent" \
  --set workloadIdentityServiceAccount="$GCP_SA_EMAIL" \
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
# rm /tmp/values-gcp.yaml

echo "Deployment completed!"
