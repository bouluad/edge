#!/bin/bash

# ==============================
# JFrog Artifactory HA Installer
# ==============================

# Set environment variables
ARTIFACTORY_VERSION="7.x.y"  # Update to the latest version
DB_URL="jdbc:postgresql://<RDS-ENDPOINT>:5432/artifactory"
DB_USER="artifactory"
DB_PASS="StrongPassword"
S3_BUCKET="my-artifactory-bucket"
AWS_REGION="us-east-1"
NODE_ID="$(hostname)"
PRIMARY_NODE_IP="<PRIMARY_NODE_PRIVATE_IP>"
ARTIFACTORY_ADMIN="admin"
ARTIFACTORY_PASSWORD="password"  # Change this
HA_KEY_FILE="/opt/artifactory/var/etc/join.key"

# Update system & install dependencies
echo "[1/7] Updating system and installing dependencies..."
sudo yum update -y || sudo apt update -y
sudo yum install -y unzip curl wget java-11-openjdk || sudo apt install -y unzip curl wget openjdk-11-jdk postgresql-client

# Create Artifactory user
echo "[2/7] Creating Artifactory user..."
sudo useradd -m -d /opt/artifactory -s /bin/bash artifactory
sudo mkdir -p /opt/artifactory
sudo chown -R artifactory:artifactory /opt/artifactory

# Download and extract Artifactory
echo "[3/7] Downloading Artifactory..."
sudo -u artifactory bash -c "
cd /opt/artifactory
curl -fL https://releases.jfrog.io/artifactory/artifactory-pro/org/artifactory/pro/jfrog-artifactory-pro/${ARTIFACTORY_VERSION}/artifactory-pro-${ARTIFACTORY_VERSION}-linux.tar.gz -o artifactory.tar.gz
tar -xvzf artifactory.tar.gz --strip-components=1
rm -f artifactory.tar.gz
"

# Generate or retrieve HA key
if [[ "$(hostname -I | awk '{print $1}')" == "$PRIMARY_NODE_IP" ]]; then
    echo "[4/7] Generating HA_KEY on primary node..."
    HA_KEY=$(openssl rand -hex 32)
    echo "$HA_KEY" | sudo tee "$HA_KEY_FILE"
else
    echo "[4/7] Retrieving HA_KEY from primary node..."
    while [[ ! -f "$HA_KEY_FILE" ]]; do
        scp artifactory@$PRIMARY_NODE_IP:$HA_KEY_FILE /tmp/join.key
        if [[ -s /tmp/join.key ]]; then
            sudo mv /tmp/join.key "$HA_KEY_FILE"
            break
        fi
        echo "Waiting for HA_KEY..."
        sleep 5
    done
    HA_KEY=$(cat "$HA_KEY_FILE")
fi

# Configure system.yaml
echo "[5/7] Configuring Artifactory..."
cat <<EOF | sudo tee /opt/artifactory/var/etc/system.yaml
shared:
  database:
    type: postgresql
    driver: org.postgresql.Driver
    url: ${DB_URL}
    username: ${DB_USER}
    password: ${DB_PASS}
  filestore:
    type: s3
    s3:
      bucketName: ${S3_BUCKET}
      region: ${AWS_REGION}
node:
  id: "${NODE_ID}"
  haEnabled: true
join:
  key: "${HA_KEY}"
EOF

# Set permissions
sudo chown -R artifactory:artifactory /opt/artifactory

# Create systemd service
echo "[6/7] Creating Artifactory systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/artifactory.service
[Unit]
Description=Artifactory Service
After=network.target

[Service]
User=artifactory
WorkingDirectory=/opt/artifactory
ExecStart=/opt/artifactory/app/bin/artifactoryctl start
ExecStop=/opt/artifactory/app/bin/artifactoryctl stop
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Start Artifactory
echo "[7/7] Starting Artifactory..."
sudo systemctl daemon-reload
sudo systemctl enable artifactory
sudo systemctl start artifactory

echo "🎉 JFrog Artifactory HA deployment completed successfully!"
