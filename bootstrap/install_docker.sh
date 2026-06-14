#!/bin/bash

# --- COLOR CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== [1/3] Starting Docker Installation on Ubuntu ===${NC}"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is already installed on this system.${NC}"
    docker --version
    exit 0
fi

echo -e "${YELLOW}📦 Installing Docker via apt...${NC}"
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl enable --now docker

# Setup user permissions to run Docker without 'sudo' where possible
echo -e "${BLUE}👥 Configuring Docker group permissions...${NC}"
if ! getent group docker > /dev/null; then
    sudo addgroup --system docker || true
fi

# Add current user to docker group
sudo adduser "$USER" docker || true

echo -e "${GREEN}✅ Docker has been successfully installed.${NC}"
echo -e "${YELLOW}⚠️ NOTE: If this is the first time you installed Docker on this session, you might need to log out and log back in to run Docker without 'sudo'.${NC}"