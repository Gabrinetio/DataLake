#!/usr/bin/env bash
# Deploy Iceberg catalog configuration to Trino container

PROXMOX_HOST="192.168.4.25"
PROXMOX_USER="root"
CONTAINER_ID="111"
LOCAL_FILE="iceberg.properties"
REMOTE_DIR="/home/datalake/trino/etc/catalog"
SSH_KEY="${HOME}/.ssh/pve3_root_id_ed25519"

echo "Deploying Iceberg catalog configuration..."
echo "Source: ${LOCAL_FILE}"
echo "Target: ${REMOTE_DIR}/"
echo ""

# Create directory in container if doesn't exist
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PROXMOX_USER}@${PROXMOX_HOST}" \
  "pct exec ${CONTAINER_ID} -- mkdir -p ${REMOTE_DIR}" || {
  echo "Error creating directory"
  exit 1
}

# Copy file from local to Proxmox
scp -i "${SSH_KEY}" -o StrictHostKeyChecking=no \
  "${LOCAL_FILE}" \
  "${PROXMOX_USER}@${PROXMOX_HOST}:/tmp/" || {
  echo "Error uploading to Proxmox"
  exit 1
}

# Copy from Proxmox to container
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PROXMOX_USER}@${PROXMOX_HOST}" \
  "pct push ${CONTAINER_ID} /tmp/${LOCAL_FILE} ${REMOTE_DIR}/${LOCAL_FILE}" || {
  echo "Error pushing to container"
  exit 1
}

echo "✅ Configuration deployed successfully"
echo ""
echo "Restarting Trino service..."
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "${PROXMOX_USER}@${PROXMOX_HOST}" \
  "pct exec ${CONTAINER_ID} -- systemctl restart trino"

echo ""
echo "⏳ Waiting 10 seconds for Trino to start..."
sleep 10

echo "✅ Deployment complete"
