#!/usr/bin/env python3
"""
Criar configuração Iceberg para Trino via SSH hop through Hive container
"""
import subprocess
import sys

config_content = """connector.name=iceberg

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
"""

hive_host = "192.168.4.33"
hive_user = "datalake"
hive_key = "/root/.ssh/db_hive_admin_id_ed25519"
proxmox_host = "192.168.4.25"
proxmox_user = "root"
container_id = "111"
target_path = "/home/datalake/trino/etc/catalog/iceberg.properties"

# Step 1: Create directory
cmd1 = [
    "ssh", "-i", hive_key, "-o", "StrictHostKeyChecking=no",
    f"{hive_user}@{hive_host}",
    f"ssh -o StrictHostKeyChecking=no {proxmox_user}@{proxmox_host} 'pct exec {container_id} -- mkdir -p /home/datalake/trino/etc/catalog'"
]

print("Step 1: Creating directory...")
result = subprocess.run(cmd1, capture_output=True, text=True)
if result.returncode != 0:
    print(f"Error: {result.stderr}")
    sys.exit(1)
print("✅ Directory created")

# Step 2: Write config file via pipe
cmd2 = [
    "ssh", "-i", hive_key, "-o", "StrictHostKeyChecking=no",
    f"{hive_user}@{hive_host}",
    f"ssh -o StrictHostKeyChecking=no {proxmox_user}@{proxmox_host} 'pct exec {container_id} -- tee {target_path} > /dev/null'"
]

print("Step 2: Writing configuration file...")
result = subprocess.run(cmd2, input=config_content, capture_output=True, text=True)
if result.returncode != 0:
    print(f"Error: {result.stderr}")
    sys.exit(1)
print("✅ Configuration file written")

# Step 3: Restart Trino
cmd3 = [
    "ssh", "-i", hive_key, "-o", "StrictHostKeyChecking=no",
    f"{hive_user}@{hive_host}",
    f"ssh -o StrictHostKeyChecking=no {proxmox_user}@{proxmox_host} 'pct exec {container_id} -- systemctl restart trino'"
]

print("Step 3: Restarting Trino...")
result = subprocess.run(cmd3, capture_output=True, text=True)
if result.returncode != 0:
    print(f"Error: {result.stderr}")
    sys.exit(1)

print("✅ Trino restarted")
print("\n⏳ Waiting 10 seconds for service to start...")
import time
time.sleep(10)

print("\n🎉 Deployment complete!")
