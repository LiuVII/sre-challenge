# scripts/deploy_gcp.sh
#!/bin/bash
set -euo pipefail

# Configuration
NAMESPACE="todo-app"
APP_HELM_CHART_PATH="./helm/todo-app"
DB_HELM_CHART_PATH="./helm/postgres"
export REPOSITORY_ID="sre-challenge-repository"
export PROJECT_ID="sre-challenge-b71f132d"
export REGION="europe-west1"
export APP_IMAGE_NAME="todo-app:latest"
export MIGRATIONS_IMAGE_NAME="todo-app-migrations:latest"

# Staging specific config
CLUSTER_NAME="sre-challenge-cluster-s"
export IP_ADDRESS="34.54.49.46"
export IP_NAME="sre-challenge-ip-s"

# Get GKE credentials
echo "Getting GKE cluster credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} --region ${REGION} --project ${PROJECT_ID}
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Create namespace if it doesn't exist
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# # Build and push Docker image
# echo "Building and pushing Docker images..."
# # docker build -t ${APP_IMAGE_NAME} -f src/Dockerfile .
# docker tag ${APP_IMAGE_NAME} ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}/${APP_IMAGE_NAME}
# docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}/${APP_IMAGE_NAME}

# # docker build -t ${MIGRATIONS_IMAGE_NAME} -f ./migrations/Dockerfile . .
# docker tag ${MIGRATIONS_IMAGE_NAME} ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}/${MIGRATIONS_IMAGE_NAME}
# docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}/${MIGRATIONS_IMAGE_NAME}

# Install/upgrade PostgreSQL chart
# echo "Deploying PostgreSQL..."
# helm upgrade --install postgres ${DB_HELM_CHART_PATH} \
#   --namespace ${NAMESPACE} \
#   --values ${DB_HELM_CHART_PATH}/values.yaml \
#   --wait \
#   --debug

# Create temporary values file from template
envsubst < ${APP_HELM_CHART_PATH}/values-gcp.yaml > /tmp/values-gcp.yaml

# Install/upgrade Todo app chart
echo "Deploying Todo app..."
helm upgrade --install todo-app ${APP_HELM_CHART_PATH} \
  --namespace ${NAMESPACE} \
  --values ${APP_HELM_CHART_PATH}/values.yaml \
  --values /tmp/values-gcp.yaml \
  --set image.repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_ID}/todo-app" \
  --set image.tag="latest" \
  --wait \
  --debug

# Clean up
# rm /tmp/values-gcp.yaml

echo "Deployment completed!"
