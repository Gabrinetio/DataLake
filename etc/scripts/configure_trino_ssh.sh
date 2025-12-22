#!/bin/bash
# Script: Configure SSH access for datalake user in Trino container
# Run this inside the container as root

set -e

echo "🔧 Configuring SSH access for datalake user..."

# Install SSH server if not installed
if ! command -v sshd &> /dev/null; then
    echo "📦 Installing OpenSSH Server..."
    apt update
    apt install -y openssh-server
fi

# Create datalake user if not exists
if ! id datalake &>/dev/null; then
    echo "👤 Creating datalake user..."
    useradd -m -s /bin/bash datalake
    echo "datalake:datalake123" | chpasswd
fi

# Configure SSH
echo "🔐 Configuring SSH..."
mkdir -p /home/datalake/.ssh
chmod 700 /home/datalake/.ssh

# Add public key (you'll need to replace this with actual key)
cat >> /home/datalake/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmJy3fKT2XcIh/6x7+M8j7Wk4a7qQz8nJf9g6z8EOw/Q datalake@local
EOF

chmod 600 /home/datalake/.ssh/authorized_keys
chown -R datalake:datalake /home/datalake/.ssh

# Configure SSH server
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Enable and start SSH
systemctl enable ssh
systemctl start ssh

# Set hostname
echo "trino.gti.local" > /etc/hostname
hostnamectl set-hostname trino.gti.local

# Add hostname to /etc/hosts (ensure correct mapping)
if [ "${USE_STATIC_HOSTS:-0}" -eq 1 ]; then
    if ! grep -q "trino.gti.local" /etc/hosts 2>/dev/null; then
        echo "192.168.4.35 trino.gti.local trino" >> /etc/hosts
    fi
else
    echo "Skipping adding trino.gti.local to /etc/hosts (USE_STATIC_HOSTS=${USE_STATIC_HOSTS:-0})"
fi

echo "✅ SSH configuration completed!"
echo "🌐 Hostname: trino.gti.local"
echo "👤 User: datalake"
echo "🔑 Password: datalake123"
echo "🧪 Test: ssh datalake@trino.gti.local"



