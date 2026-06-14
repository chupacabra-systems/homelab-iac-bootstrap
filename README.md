# Homelab IaC Bootstrap

This repository contains scripts to bootstrap a fresh Ubuntu machine with Docker and [Semaphore UI](https://semaphoreui.com/) for Infrastructure as Code (IaC) orchestration.

## 🚀 Quick Start (All-in-One)

To run the complete bootstrap process (installing Docker and deploying Semaphore UI) interactively, you can download and execute the orchestrator script directly from GitHub:

```bash
wget -qO- https://raw.githubusercontent.com/chupacabra-systems/homelab-iac-bootstrap/feature/poc/bootstrap/bootstrap_orchestrator.sh | bash
```

*(Note: You can also pass arguments to the orchestrator, like `-s` for silent mode, by downloading it first: `curl -O ... && bash bootstrap_orchestrator.sh -s`)*

## 🛠️ Execute Scripts Independently

If you prefer to run specific stages of the setup, you can execute each script independently directly from the raw GitHub URLs.

### 1. Install Docker Only

Installs Docker and configures the `docker` user groups:

```bash
wget -qO- https://raw.githubusercontent.com/chupacabra-systems/homelab-iac-bootstrap/feature/poc/bootstrap/install_docker.sh | bash
```

### 2. Deploy Semaphore UI Only

Assuming Docker is already installed, this script sets up the persistence directory and spins up the Semaphore UI container.

```bash
wget -qO- https://raw.githubusercontent.com/chupacabra-systems/homelab-iac-bootstrap/feature/poc/bootstrap/deploy_semaphore.sh | bash
```

**Customizing the Semaphore Deployment:**
You can customize the deployment by setting environment variables before executing the script:

```bash
export SEMAPHORE_PORT="8080"
export SEMAPHORE_PASSWORD="MySuperSecretPassword"
export SEMAPHORE_USER="admin"
wget -qO- https://raw.githubusercontent.com/chupacabra-systems/homelab-iac-bootstrap/feature/poc/bootstrap/deploy_semaphore.sh | bash
```
