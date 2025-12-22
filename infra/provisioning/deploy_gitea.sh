#!/bin/bash
# Deploy Gitea to CT 118 (gitea.gti.local - 192.168.4.26)

SSH_OPTS="-i /root/.ssh/pve3_root_id_ed25519 -o StrictHostKeyChecking=no"
CT_ID=118

echo "Deploying Gitea to CT $CT_ID..."

# Install essential packages
echo "Installing packages..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- apt update"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- apt upgrade -y"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- apt install -y curl wget git vim openssh-server ca-certificates postgresql postgresql-contrib"

# Create datalake user
echo "Creating datalake user..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- adduser datalake --gecos \"Datalake User,,,\" --disabled-password"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- usermod -aG sudo datalake"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- bash -c 'echo "datalake:<<SENHA_FORTE>>" | chpasswd'"  # Recomendado: obter senha do Vault/gerenciador de segredos

# Setup PostgreSQL
echo "Setting up PostgreSQL..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl enable postgresql"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl start postgresql"

# Create Gitea database and user
echo "Creating Gitea database..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- sudo -u postgres psql -c \"CREATE USER gitea WITH PASSWORD '<<SENHA_FORTE>>';  -- substitua por senha gerada e armazenada em cofre\""
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- sudo -u postgres psql -c \"CREATE DATABASE gitea OWNER gitea;\""
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;\""

# Download and install Gitea
echo "Installing Gitea..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- wget -O /usr/local/bin/gitea https://dl.gitea.com/gitea/1.24.2/gitea-1.24.2-linux-amd64"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- chmod +x /usr/local/bin/gitea"

# Create directories
echo "Creating directories..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- mkdir -p /var/lib/gitea/{custom,data,log}"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- mkdir -p /etc/gitea"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- chown -R datalake:datalake /var/lib/gitea"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- chown -R datalake:datalake /etc/gitea"

# Create systemd service
echo "Creating systemd service..."
cat > /tmp/gitea.service << 'EOF'
[Unit]
Description=Gitea Git Service
After=network.target postgresql.service

[Service]
User=datalake
Group=datalake
WorkingDirectory=/var/lib/gitea
ExecStart=/usr/local/bin/gitea web -c /etc/gitea/app.ini
Restart=always
Environment=USER=datalake HOME=/home/datalake GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
EOF

ssh $SSH_OPTS root@192.168.4.25 "pct push $CT_ID /tmp/gitea.service /etc/systemd/system/gitea.service"

# Enable and start service
echo "Starting Gitea service..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl daemon-reload"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl enable gitea"
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl start gitea"

# Wait for startup
echo "Waiting for Gitea to start..."
sleep 10

# Check status
echo "Checking Gitea status..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec $CT_ID -- systemctl status gitea --no-pager | head -10"

echo "Gitea deployed successfully!"
echo "Access at: http://192.168.4.26:3000"
echo "Complete initial setup via web interface."