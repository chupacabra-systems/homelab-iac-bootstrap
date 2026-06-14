#!/bin/bash

# --- COLOR CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- UPDATE THESE TO POINT TO YOUR GITHUB REPO ---
GITHUB_USER="chupacabra-systems"
GITHUB_REPO="homelab-iac-bootstrap"
GITHUB_BRANCH="feature/poc"

# Default Controller Parameters
SILENT_MODE=false
SEMAPHORE_PORT="3000"
SEMAPHORE_PASSWORD="MySecurePassword123"

# --- CLI ARGUMENTS PARSER ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--silent) SILENT_MODE=true ;;
        -p|--port) SEMAPHORE_PORT="$2"; shift ;;
        -w|--password) SEMAPHORE_PASSWORD="$2"; shift ;;
        -u|--user) GITHUB_USER="$2"; shift ;;
        -r|--repo) GITHUB_REPO="$2"; shift ;;
        -b|--branch) GITHUB_BRANCH="$2"; shift ;;
        -h|--help)
            echo "Usage: ./bootstrap_orchestrator.sh [OPTIONS]"
            echo "Options:"
            echo "  -s, --silent      Non-interactive mode (uses defaults or CLI parameters)"
            echo "  -p, --port        Semaphore UI service port (default: 3000)"
            echo "  -w, --password    Set custom Semaphore Admin password"
            echo "  -u, --user        Target GitHub username/org"
            echo "  -r, --repo        Target GitHub repository name"
            echo "  -b, --branch      Target GitHub branch (default: main)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

echo -e "${BLUE}🚀 === [3/3] Initiating Core Orchestration Engine ===${NC}"

# Base URL construction
BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/bootstrap"

# Interactive mode handling
if [ "$SILENT_MODE" = false ]; then
    echo -e "${YELLOW}📋 Running in Interactive Mode.${NC}"
    
    read -p "❔ Do you want to configure a custom port for Semaphore? (Default 3000): " input_port
    if [ ! -z "$input_port" ]; then
        SEMAPHORE_PORT=$input_port
    fi

    read -s -p "❔ Enter Admin Password for Semaphore: " input_pass
    echo ""
    if [ ! -z "$input_pass" ]; then
        SEMAPHORE_PASSWORD=$input_pass
    fi
else
    echo -e "${YELLOW}🤖 Running in Silent Mode. Applying automated values...${NC}"
fi

# Utility function to pull and execute secondary scripts
execute_remote_script() {
    local script_name=$1
    local script_url="${BASE_URL}/${script_name}"
    
    echo -e "${BLUE}📥 Downloading ${script_name} from GitHub...${NC}"
    wget -q "$script_url" -O "$script_name"
    
    if [ $? -ne 0 ] || [ ! -f "$script_name" ]; then
        echo -e "${RED}❌ Critical Error: Could not retrieve ${script_name}.${NC}"
        echo -e "${RED}Verify your repo configuration URL: ${script_url}${NC}"
        exit 1
    fi
    
    chmod +x "$script_name"
    
    echo -e "${BLUE}⚙️ Executing ${script_name}...${NC}"
    # Export parameters down to deployment environment
    export SEMAPHORE_PORT="$SEMAPHORE_PORT"
    export SEMAPHORE_PASSWORD="$SEMAPHORE_PASSWORD"
    
    ./"$script_name"
    
    # Run immediate local clean-up of scripts
    rm -f "$script_name"
}

# --- PIPELINE INITIALIZATION ---

# Step 1: Provision host Docker platform
execute_remote_script "install_docker.sh"

# Step 2: Provision Semaphore web service 
execute_remote_script "deploy_semaphore.sh"

echo -e "${GREEN}🎉 Bootstrap initialization sequence finished successfully!${NC}"