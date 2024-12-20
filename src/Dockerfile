# src/Dockerfile
FROM python:3.11-slim

# Add system dependencies including user management tools
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        passwd \
    && rm -rf /var/lib/apt/lists/*

# Add non-root user
RUN groupadd -r app && useradd -r -g app app

WORKDIR /app

# Install dependencies first (better layer caching)
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/app/ .

# Set ownership
RUN chown -R app:app /app

# Switch to non-root user
USER app

EXPOSE 8080

CMD ["python", "main.py"]
