#!/bin/bash
# Deploy Iceberg catalog to Trino container

# Configuration content
ICEBERG_CONFIG="connector.name=iceberg

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
iceberg.register-table-procedure.enabled=true"

# SSH to Hive, then create config in Trino
echo "$ICEBERG_CONFIG" | ssh -i ~/.ssh/db_hive_admin_id_ed25519 -o StrictHostKeyChecking=no \
  datalake@192.168.4.32 \
  'ssh -o StrictHostKeyChecking=no root@192.168.4.25 "pct push 111 /dev/stdin /home/datalake/trino/etc/catalog/iceberg.properties"'

echo "Restarting Trino..."
ssh -i ~/.ssh/db_hive_admin_id_ed25519 -o StrictHostKeyChecking=no \
  datalake@192.168.4.32 \
  'ssh -o StrictHostKeyChecking=no root@192.168.4.25 "pct exec 111 -- systemctl restart trino"'

echo "Done!"





