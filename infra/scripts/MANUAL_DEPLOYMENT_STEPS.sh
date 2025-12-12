#!/usr/bin/env bash
# Generate deployment commands that can be executed manually

CONTAINER_ID="111"
REMOTE_PATH="/home/datalake/trino/etc/catalog/iceberg.properties"

cat <<'EOF'
# ==============================================================
# MANUAL DEPLOYMENT STEPS FOR ICEBERG CATALOG
# ==============================================================
# Execute these commands sequentially on the Proxmox host
# ==============================================================

# Step 1: Create the configuration file on Proxmox host
cat > /tmp/iceberg.properties << 'EOCONFIG'
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
EOCONFIG

# Step 2: Push file to container
pct push 111 /tmp/iceberg.properties /home/datalake/trino/etc/catalog/iceberg.properties

# Step 3: Restart Trino
pct exec 111 -- systemctl restart trino

# Step 4: Wait for startup
sleep 10

# Step 5: Verify deployment
pct exec 111 -- ls -la /home/datalake/trino/etc/catalog/
pct exec 111 -- systemctl status trino --no-pager

EOF
