# scripts/dev_run.sh
#!/bin/bash

set -e

echo "Starting local development environment..."

# Check if running containers exist
if docker compose ps | grep -q "todo-app"; then
    echo "Stopping existing containers..."
    docker compose down
fi

# Start everything
docker compose up --build -d

echo "
Local development environment is ready:
- Todo app: http://localhost:8080
- Primary DB: localhost:5432
- Replica DB: localhost:5433

Logs can be viewed with: docker compose logs -f
"