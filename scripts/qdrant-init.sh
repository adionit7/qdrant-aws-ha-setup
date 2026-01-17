#!/bin/bash
set -e

# Qdrant High Availability Setup Script
# This script installs and configures Qdrant on Amazon Linux 2023

QDRANT_VERSION="${qdrant_version}"
CLUSTER_MODE="${cluster_mode}"

# Update system
sudo dnf update -y

# Install dependencies
sudo dnf install -y \
    docker \
    curl \
    wget \
    unzip \
    jq

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64"
sudo curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create Qdrant data directory
sudo mkdir -p /opt/qdrant/data
sudo mkdir -p /opt/qdrant/config
sudo chown -R ec2-user:ec2-user /opt/qdrant

# Create Qdrant configuration file
cat > /opt/qdrant/config/production.yaml <<EOF
log_level: INFO

service:
  http_port: 6333
  grpc_port: 6334

storage:
  storage_path: /qdrant/storage
  snapshots_path: /qdrant/snapshots

cluster:
  enabled: $CLUSTER_MODE
  p2p:
    port: 6335

telemetry_disabled: false
max_optimization_threads: 2
max_indexing_threads: 2
EOF

# Create Qdrant Docker Compose file
cat > /opt/qdrant/docker-compose.yml <<EOF
version: '3.8'

services:
  qdrant:
    image: qdrant/qdrant:v$QDRANT_VERSION
    container_name: qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
      - "6335:6335"
    volumes:
      - ./data:/qdrant/storage
      - ./config/production.yaml:/qdrant/config/production.yaml
    environment:
      - QDRANT__CONFIG_PATH=/qdrant/config/production.yaml
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    ulimits:
      memlock: -1
      nofile:
        soft: 65536
        hard: 65536
EOF

# Start Qdrant using Docker Compose
cd /opt/qdrant
sudo docker-compose up -d

# Wait for Qdrant to be ready
echo "Waiting for Qdrant to start..."
for i in {1..30}; do
    if curl -f http://localhost:6333/health > /dev/null 2>&1; then
        echo "Qdrant is ready!"
        break
    fi
    echo "Attempt $i: Waiting for Qdrant..."
    sleep 5
done

# Verify Qdrant is running
if curl -f http://localhost:6333/health > /dev/null 2>&1; then
    echo "Qdrant installation completed successfully!"
    curl http://localhost:6333/health
else
    echo "Warning: Qdrant health check failed"
fi

# Create systemd service for Qdrant (optional, for better process management)
cat > /tmp/qdrant.service <<EOF
[Unit]
Description=Qdrant Vector Database
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/qdrant
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/qdrant.service /etc/systemd/system/qdrant.service
sudo systemctl daemon-reload
sudo systemctl enable qdrant.service

# Log installation completion
echo "Qdrant v$QDRANT_VERSION installed and started at $(date)" >> /var/log/qdrant-install.log
