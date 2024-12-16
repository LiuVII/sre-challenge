# Development Guide
This guide covers local development setup and testing procedures.

## Prerequisites
### Required Tools
For app development
- Docker & Docker Compose (27.3.1+)
- Python 3.11+

Extra for local infrastructure testing
- kubectl (v1.30.2+)
- helm (v3.15.2+)
- k3d (v5.7.5+)

## Local Development
Clone the repository:
```bash
git clone https://github.com/LiuVII/sre-challenge.git
cd sre-challenge
```

### Local App Development/Testing
The fastest way to start development is using Docker Compose:
```bash
chmod +x scripts/dev_run.sh

./scripts/dev_run.sh
```
  
This will:
- Start PostgreSQL main instance
- Run database migrations
- Run application tests
- Start the todo application
- Access the app at http://localhost:8080

Tear down using
```bash
docker compose down

# To also remove all db data run this instead
docker-compose down -v
```

To test via docker compose
```bash
docker compose run test
```

To test directly
```bash
# Note: make sure if really want to run this like that or use some isolated env like venv
pip install -r src/requirements.txt

python -m pytest src/tests/
```

### Local Kubernetes Testing
To test complete Kubernetes setup locally:
```bash
chmod +x scripts/deploy_k3d.sh

./scripts/deploy_k3d.sh
```

This creates a local k3d cluster with:
- PostgreSQL primary and replica
- Database migrations
- Todo application
- Local ingress access
- Access the app at http://localhost:8080

When done kill provided port-forward PID and tear down k3d cluster
```bash
# PID will be shown in the script output

k3d cluster delete todo-app-cluster
```

## Database Migrations
Migrations are managed via Liquibase and run automatically during deployment.
To add new migrations:
1. Create new changelog in migrations/changelog-master.yaml
2. Test locally using dev environment (runs with 'dev' context)
3. Migrations will run with proper contexts in staging/production ('stage'/'prod' contexts)
