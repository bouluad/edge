#!/bin/bash

# Artifactory HA Deployment Script with Local Master Key Management
# Run this same script on both nodes - it auto-detects primary/secondary

set -e  # Exit on error

## ========================
## CONFIGURATION VARIABLES
## ========================

# Common Configuration
DB_ENDPOINT="artifactory-db.cluster-123.eu-west-1.rds.amazonaws.com"
DB_USER="artifactory"
DB_PASSWORD="MyDBPassword123"
DB_NAME="artdb"
DB_TYPE="postgresql"

S3_BUCKET="my-artifactory-bucket"
AWS_REGION="eu-west-1"
ARTIFACTORY_VERSION="7.68.13"

# HA Configuration
MASTER_KEY_FILE="/var/opt/jfrog/artifactory/ha_master.key"
NODE_ID=$(hostname -s)

## ========================
## FUNCTIONS
## ========================

install_artifactory() {
  echo -e "\n\033[1;34mInstalling Artifactory on $(hostname)\033[0m"
  
  # Install dependencies
  sudo yum install -y java-11-openjdk-devel wget
  
  # Download and install Artifactory
  wget "https://releases.jfrog.io/artifactory/artifactory-rpms/artifactory-pro-${ARTIFACTORY_VERSION}.rpm" -O jfrog-artifactory-pro.rpm
  sudo yum install -y jfrog-artifactory-pro.rpm

  # Configure system.yaml
  cat <<EOF | sudo tee /etc/opt/jfrog/artifactory/system.yaml
shared:
  node:
    id: "${NODE_ID}"
  database:
    type: ${DB_TYPE}
    driver: org.${DB_TYPE}.Driver
    url: jdbc:${DB_TYPE}://${DB_ENDPOINT}:5432/${DB_NAME}
    username: ${DB_USER}
    password: "${DB_PASSWORD}"
  filestore:
    binaryProvider:
      type: s3
      s3:
        bucketName: "${S3_BUCKET}"
        region: "${AWS_REGION}"
EOF

  # Set master key
  echo "${MASTER_KEY}" | sudo tee /var/opt/jfrog/artifactory/etc/security/master.key
  sudo chown artifactory:artifactory /var/opt/jfrog/artifactory/etc/security/master.key
  
  # Start service
  sudo systemctl start artifactory
  sudo systemctl enable artifactory
}

generate_master_key() {
  echo -e "\033[1;33mGenerating new master key...\033[0m"
  MASTER_KEY=$(openssl rand -hex 32)
  echo "$MASTER_KEY" | sudo tee "$MASTER_KEY_FILE" >/dev/null
  sudo chown artifactory:artifactory "$MASTER_KEY_FILE"
  sudo chmod 600 "$MASTER_KEY_FILE"
}

get_master_key() {
  if [ -f "$MASTER_KEY_FILE" ]; then
    MASTER_KEY=$(sudo cat "$MASTER_KEY_FILE")
  else
    echo -e "\033[1;31mERROR: Master key file not found\033[0m"
    exit 1
  fi
}

## ========================
## MAIN SCRIPT
## ========================

echo -e "\033[1;36mStarting Artifactory HA Node Configuration\033[0m"
echo "Node ID: ${NODE_ID}"

# Master key handling
if [ "$1" == "--primary" ]; then
  # Explicit primary node setup
  generate_master_key
  echo -e "\033[1;32mConfigured as PRIMARY node (new master key generated)\033[0m"
else
  # Normal operation - try to use existing key
  if [ -f "$MASTER_KEY_FILE" ]; then
    get_master_key
    echo -e "\033[1;32mConfigured as SECONDARY node (using existing master key)\033[0m"
  else
    echo -e "\033[1;31mERROR: Master key not found. Run with --primary on first node.\033[0m"
    echo "Usage:"
    echo "  On primary node: $0 --primary"
    echo "  On secondary nodes: $0"
    exit 1
  fi
fi

# Install and configure Artifactory
install_artifactory

# Verify installation
echo -e "\n\033[1;34mVerifying Artifactory status...\033[0m"
curl -s http://localhost:8082/artifactory/api/system/ping

echo -e "\n\033[1;36mArtifactory Node Configuration Complete\033[0m"
echo "Node ID: ${NODE_ID}"
echo "Hostname: $(hostname)"
