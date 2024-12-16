# Deployment Guide

This guide primarily covers application deployment to existing GKE infrastructure. For complete project setup, please contact repository maintainers.

## General prerequisites
- Access to GCP project `sre-challenge-b71f132d` (request access if you don't have)

## Application Deployment
### Prerequisites
- Configured gcloud CLI (at least 410.0.0)
- kubectl (v1.30.2+) and helm (v3.15.2+) installed

### Quick Deploy
To deploy an existing version to staging:
```bash
# Note set version after -t e.g. for 1.0.2
./scripts/deploy_gcp.sh -t 1.0.2
```

To build, push, and deploy a new version:
```bash
# First ensure you have authenticated with GCP
gcloud auth login

# Then build, push and deploy
./scripts/deploy_gcp.sh -t 1.2.3 -b
```

The script will:
- Optionally build and push Docker images to GAR
- Deploy PostgreSQL with replication (if there updates to make)
- Run database migrations (if there any to run)
- Deploy todo application (if there's a new version to deploy)

Once deployed, the application will be available at https://34.54.49.46.nip.io/

## Infrastructure Setup (Optional)

###
- OpenTofu 1.8+ (optional, only necessary for terraform deployments)

To apply 0-project changes 
```bash
cd terraform/0-project
tofu init
tofu apply
```
if these changes affect outputs plan/apply for 1-environments also must be run

To apply 1-environments changes
```bash
cd terraform/1-environments/staging  # or prod
tofu init
tofu apply
```

## New/Fresh project initialization
If you're interested in instantiating this project yourself please contact repository maintainer for detailed infrastructure setup instructions.
