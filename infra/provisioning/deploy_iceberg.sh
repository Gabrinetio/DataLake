#!/bin/bash
# Deploy Iceberg catalog to Trino via Proxmox

SSH_OPTS="-i /root/.ssh/pve3_root_id_ed25519 -o StrictHostKeyChecking=no"
CONFIG_FILE="/tmp/iceberg_config.properties"

# Content to deploy
cat > "$CONFIG_FILE" << 'EOF'
connector.name=iceberg

catalog.type=hadoop
warehouse=s3a://datalake/warehouse/iceberg

fs.native-s3.enabled=true
s3.endpoint=http://192.168.4.33:9000
s3.path-style-access=true
s3.aws-access-key=datalake
s3.aws-secret-key=iRB;g2&ChZ&XQEW!
s3.ssl.enabled=false

iceberg.file-format=parquet
iceberg.max-partitions-per-scan=1000
iceberg.register-table-procedure.enabled=true
EOF

echo "Deploying Iceberg configuration..."

# Push to container
ssh $SSH_OPTS root@192.168.4.25 "pct push 111 $CONFIG_FILE /home/datalake/trino/etc/catalog/iceberg.properties"

echo "Restarting Trino..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec 111 -- systemctl restart trino"

echo "Waiting for Trino to start..."
sleep 10

# Verify
echo "Checking Trino status..."
ssh $SSH_OPTS root@192.168.4.25 "pct exec 111 -- systemctl status trino --no-pager | head -10"

echo "Done!"
