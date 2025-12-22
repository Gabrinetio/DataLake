#!/usr/bin/env bash
# SSH Jump Host approach - deploy Iceberg via Hive container

CONFIG_FILE="/tmp/iceberg_deploy.properties"

cat > "$CONFIG_FILE" << 'ENDCONFIG'
connector.name=iceberg

catalog.type=hadoop
warehouse=s3a://datalake/warehouse/iceberg

fs.native-s3.enabled=true
s3.endpoint=http://192.168.4.32:9000
s3.path-style-access=true
s3.aws-access-key=datalake
s3.aws-secret-key=iRB;g2&ChZ&XQEW!
s3.ssl.enabled=false

iceberg.file-format=parquet
iceberg.max-partitions-per-scan=1000
iceberg.register-table-procedure.enabled=true
ENDCONFIG

echo "Configuration file created: $CONFIG_FILE"
echo ""
echo "Deploying to Trino container..."

# Via SSH Jump Host (Hive container acts as jump host)
ssh -i ~/.ssh/db_hive_admin_id_ed25519 -o StrictHostKeyChecking=no \
  -o "ProxyCommand=ssh -i ~/.ssh/db_hive_admin_id_ed25519 -o StrictHostKeyChecking=no -W %h:%p datalake@192.168.4.32" \
  root@192.168.4.25 \
  "pct push 111 $CONFIG_FILE /home/datalake/trino/etc/catalog/iceberg.properties && pct exec 111 -- systemctl restart trino"

echo ""
echo "Deployment sent. Waiting 10 seconds for Trino to restart..."
sleep 10

echo "✅ Done!"





