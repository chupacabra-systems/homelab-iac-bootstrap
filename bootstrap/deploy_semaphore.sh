#!/bin/bash

# --- COLOR CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- DEFAULT VARIABLES ---
SEMAPHORE_PORT=${SEMAPHORE_PORT:-3000}
SEMAPHORE_PASSWORD=${SEMAPHORE_PASSWORD:-"MySecurePassword123"}
SEMAPHORE_USER=${SEMAPHORE_USER:-"admin"}
SEMAPHORE_EMAIL=${SEMAPHORE_EMAIL:-"admin@mylocaldev.lan"}

echo -e "${BLUE}=== [2/3] Starting Semaphore UI Deployment ===${NC}"

# Verify Docker is installed and available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed or not available in the current PATH.${NC}"
    exit 1
fi

# Detect if we need sudo fallback (in case the shell session hasn't refreshed group permissions yet)
DOCKER_CMD="docker"
if ! docker ps &> /dev/null; then
    DOCKER_CMD="sudo docker"
fi

# Check for pre-existing Semaphore container and remove it to avoid conflicts
if [ "$($DOCKER_CMD ps -aq -f name=semaphore)" ]; then
    echo -e "${YELLOW}⚠️ Found existing Semaphore container. Removing to redeploy...${NC}"
    $DOCKER_CMD rm -f semaphore &>/dev/null || true
fi
if [ "$($DOCKER_CMD ps -aq -f name=semaphore-postgres)" ]; then
    echo -e "${YELLOW}⚠️ Found existing Postgres container. Removing to redeploy...${NC}"
    $DOCKER_CMD rm -f semaphore-postgres &>/dev/null || true
fi

# Create secure host path for database and SSH keys persistence
DATA_DIR="$HOME/semaphore_data"
echo -e "${BLUE}📂 Creating persistence directories at: $DATA_DIR${NC}"
mkdir -p "$DATA_DIR/semaphore"
mkdir -p "$DATA_DIR/postgres"

# The Semaphore UI container runs as an unprivileged user (UID 1001) for security.
# We must grant this user ownership of the host directory to prevent 'permission denied' database panics.
sudo chown -R 1001:1001 "$DATA_DIR/semaphore"

echo -e "${BLUE}🔗 Creating Docker network 'semaphore-net'...${NC}"
$DOCKER_CMD network create semaphore-net &>/dev/null || true

# Run PostgreSQL database container
echo -e "${BLUE}🐘 Spinning up PostgreSQL database container...${NC}"
$DOCKER_CMD run -d \
  --name semaphore-postgres \
  --network semaphore-net \
  --restart unless-stopped \
  -v "${DATA_DIR}/postgres:/var/lib/postgresql/data" \
  -e POSTGRES_USER=semaphore \
  -e POSTGRES_PASSWORD=semaphore \
  -e POSTGRES_DB=semaphore \
  postgres:15-alpine

# Run official Semaphore container using PostgreSQL
echo -e "${BLUE} Spinning up Semaphore UI container on port $SEMAPHORE_PORT...${NC}"

$DOCKER_CMD run -d \
  --name semaphore \
  --network semaphore-net \
  --restart unless-stopped \
  -p "${SEMAPHORE_PORT}:3000" \
  -v "${DATA_DIR}/semaphore:/var/lib/semaphore" \
  -e SEMAPHORE_DB_DIALECT=postgres \
  -e SEMAPHORE_DB_HOST=semaphore-postgres \
  -e SEMAPHORE_DB_PORT=5432 \
  -e SEMAPHORE_DB_USER=semaphore \
  -e SEMAPHORE_DB_PASS=semaphore \
  -e SEMAPHORE_DB=semaphore \
  -e SEMAPHORE_ADMIN="${SEMAPHORE_USER}" \
  -e SEMAPHORE_ADMIN_PASSWORD="${SEMAPHORE_PASSWORD}" \
  -e SEMAPHORE_ADMIN_NAME="Lab Admin" \
  -e SEMAPHORE_ADMIN_EMAIL="${SEMAPHORE_EMAIL}" \
  semaphoreui/semaphore:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Semaphore UI deployed successfully!${NC}"
    echo -e "${GREEN}🌐 Access it via your browser: http://sandbox1.lan:${SEMAPHORE_PORT}${NC}"
    echo -e "${YELLOW}👤 Username: ${SEMAPHORE_USER}${NC}"
    echo -e "${YELLOW}🔑 Password: ${SEMAPHORE_PASSWORD}${NC}"
else
    echo -e "${RED}❌ Failed to deploy Semaphore UI container.${NC}"
    exit 1
fi