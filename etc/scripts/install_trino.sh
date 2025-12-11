#!/bin/bash
# Script: Install Trino on Debian 12
# Usage: ./install_trino.sh
# Requirements: Run as root, Java 17+ installed

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Trino Installation${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Please run as root${NC}"
  exit 1
fi

# Check Java
echo -e "${YELLOW}📋 Checking Java installation...${NC}"
if ! java -version 2>&1 | grep -q "17\|21"; then
  echo -e "${RED}❌ Java 17+ required. Installing OpenJDK 17...${NC}"
  apt update
  apt install -y openjdk-17-jdk
fi

echo -e "${GREEN}✅ Java OK: $(java -version 2>&1 | head -n 1)${NC}"

# Create trino user
echo -e "${YELLOW}👤 Creating Trino user...${NC}"
useradd -r -s /bin/false trino 2>/dev/null || echo "User already exists"

# Download and extract Trino
TRINO_VERSION="478"
TRINO_URL="https://repo1.maven.org/maven2/io/trino/trino-server/${TRINO_VERSION}/trino-server-${TRINO_VERSION}.tar.gz"

echo -e "${YELLOW}📦 Downloading Trino ${TRINO_VERSION}...${NC}"
wget -q ${TRINO_URL} -O /tmp/trino-server-${TRINO_VERSION}.tar.gz

echo -e "${YELLOW}📦 Extracting Trino...${NC}"
tar -xzf /tmp/trino-server-${TRINO_VERSION}.tar.gz -C /opt/
mv /opt/trino-server-${TRINO_VERSION} /opt/trino
chown -R trino:trino /opt/trino

# Create directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p /var/trino/data
mkdir -p /opt/trino/etc/catalog
chown -R trino:trino /var/trino

# Node properties
echo -e "${YELLOW}⚙️  Configuring node properties...${NC}"
cat > /opt/trino/etc/node.properties << EOF
node.environment=production
node.id=$(uuidgen)
node.data-dir=/var/trino/data
EOF

# JVM config
echo -e "${YELLOW}⚙️  Configuring JVM...${NC}"
cat > /opt/trino/etc/jvm.config << EOF
-server
-Xmx4G
-Xms2G
-XX:+UseG1GC
-XX:G1HeapRegionSize=32m
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-Djdk.attach.allowAttachSelf=true
-Djava.net.preferIPv4Stack=true
EOF

# Config properties (Coordinator)
echo -e "${YELLOW}⚙️  Configuring coordinator...${NC}"
cat > /opt/trino/etc/config.properties << EOF
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
discovery.uri=http://localhost:8080
EOF

# Log properties
echo -e "${YELLOW}⚙️  Configuring logging...${NC}"
cat > /opt/trino/etc/log.properties << EOF
io.trino=INFO
EOF

# Iceberg catalog
echo -e "${YELLOW}🗂️  Configuring Iceberg catalog...${NC}"
cat > /opt/trino/etc/catalog/iceberg.properties << EOF
connector.name=hive
hive.metastore.uri=thrift://192.168.4.33:9083
hive.s3.endpoint=http://192.168.4.33:9000
hive.s3.access-key=datalake
hive.s3.secret-key=iRB;g2&ChZ&XQEW!
hive.s3.path-style-access=true
hive.s3.ssl.enabled=false
EOF

# Create systemd service
echo -e "${YELLOW}🔧 Creating systemd service...${NC}"
cat > /etc/systemd/system/trino.service << EOF
[Unit]
Description=Trino SQL Engine
After=network.target

[Service]
Type=simple
User=trino
Group=trino
ExecStart=/opt/trino/bin/launcher run
ExecStop=/opt/trino/bin/launcher stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable trino

# Start Trino
echo -e "${YELLOW}🚀 Starting Trino service...${NC}"
systemctl start trino

# Wait for startup
echo -e "${YELLOW}⏳ Waiting for Trino to start...${NC}"
sleep 10

# Check status
if systemctl is-active --quiet trino; then
  echo -e "${GREEN}✅ Trino started successfully!${NC}"

  # Test connection
  echo -e "${YELLOW}🧪 Testing connection...${NC}"
  if curl -s http://localhost:8080/v1/info | grep -q "starting\|running"; then
    echo -e "${GREEN}✅ Trino web UI responding${NC}"
  else
    echo -e "${YELLOW}⚠️  Web UI not responding yet, but service is active${NC}"
  fi

  echo -e "${GREEN}🎉 Trino installation completed!${NC}"
  echo -e "${GREEN}🌐 Access: http://localhost:8080${NC}"
  echo -e "${GREEN}📊 Status: systemctl status trino${NC}"
  echo -e "${GREEN}📝 Logs: journalctl -u trino -f${NC}"

else
  echo -e "${RED}❌ Trino failed to start${NC}"
  echo -e "${YELLOW}📝 Check logs: journalctl -u trino -n 50${NC}"
  exit 1
fi

# Cleanup
rm -f /tmp/trino-server-${TRINO_VERSION}.tar.gz

echo -e "${GREEN}🧹 Cleanup completed${NC}"</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\etc\scripts\install_trino.sh