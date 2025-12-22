#!/usr/bin/env bash
set -euo pipefail

# install-kafka-ui.sh
# Instala Kafka UI (Standalone Jar) no container
# Uso: install-kafka-ui.sh [VERSION]

VERSION=${1:-0.7.2}
INSTALL_DIR="/opt/kafka-ui"
JAR_URL="https://github.com/provectus/kafka-ui/releases/download/v${VERSION}/kafka-ui-api-v${VERSION}.jar"
KAFKA_USER="kafka"

echo "=== Installing Kafka UI v${VERSION} ==="

# 1. Install Java 17 if missing
if ! java -version 2>&1 | grep -q "17"; then
    echo "Installing OpenJDK 17..."
    apt-get update
    apt-get install -y openjdk-17-jdk
fi

# 2. Prepare Directory
mkdir -p "$INSTALL_DIR"
chown "$KAFKA_USER:$KAFKA_USER" "$INSTALL_DIR"

# 3. Download Jar
echo "Downloading $JAR_URL..."
wget -q "$JAR_URL" -O "$INSTALL_DIR/kafka-ui-api.jar"
chown "$KAFKA_USER:$KAFKA_USER" "$INSTALL_DIR/kafka-ui-api.jar"

# 4. Create Configuration
echo "Creating application.yml..."
cat > "$INSTALL_DIR/application.yml" <<EOF
server:
  port: 8080

kafka:
  clusters:
    - name: local
      bootstrapServers: localhost:9092
      properties:
        security.protocol: PLAINTEXT
EOF
chown "$KAFKA_USER:$KAFKA_USER" "$INSTALL_DIR/application.yml"

# 5. Create Systemd Service
echo "Creating systemd service..."
cat > /etc/systemd/system/kafka-ui.service <<EOF
[Unit]
Description=Kafka UI
After=network.target kafka.service

[Service]
User=$KAFKA_USER
ExecStart=/usr/bin/java -jar $INSTALL_DIR/kafka-ui-api.jar --spring.config.additional-location=$INSTALL_DIR/application.yml
SuccessExitStatus=143
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 6. Enable and Start
echo "Starting Kafka UI..."
systemctl daemon-reload
systemctl enable kafka-ui
systemctl restart kafka-ui

echo "Kafka UI installed and started on port 8080."
