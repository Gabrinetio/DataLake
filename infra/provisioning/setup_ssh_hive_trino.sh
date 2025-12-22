#!/bin/bash
# Script to setup SSH access from local machine to Trino container via Hive jump host

HIVE_HOST="192.168.4.32"
HIVE_USER="datalake"
HIVE_KEY="$HOME/.ssh/db_hive_admin_id_ed25519"

TRINO_HOST="192.168.4.35"
TRINO_USER="datalake"

echo "=== SSH Setup Script: Hive -> Trino ==="
echo ""
echo "1. Verifying Hive connection..."
ssh -i "$HIVE_KEY" -o StrictHostKeyChecking=no "$HIVE_USER@$HIVE_HOST" "echo '✅ Connected to Hive'"

echo ""
echo "2. Generating SSH key on Hive for Trino access..."
ssh -i "$HIVE_KEY" -o StrictHostKeyChecking=no "$HIVE_USER@$HIVE_HOST" \
  'ssh-keygen -t ed25519 -f ~/.ssh/id_trino -N "" -C "datalake@hive-for-trino" && echo "✅ Key generated"'

echo ""
echo "3. Getting public key..."
PUB_KEY=$(ssh -i "$HIVE_KEY" -o StrictHostKeyChecking=no "$HIVE_USER@$HIVE_HOST" 'cat ~/.ssh/id_trino.pub')
echo "Public key: $PUB_KEY"

echo ""
echo "4. Adding Trino to known_hosts on Hive..."
ssh -i "$HIVE_KEY" -o StrictHostKeyChecking=no "$HIVE_USER@$HIVE_HOST" \
  'ssh-keyscan -H ${TRINO_HOST} >> ~/.ssh/known_hosts 2>/dev/null && echo "✅ Added"'

echo ""
echo "5. Creating SSH config on Hive..."
ssh -i "$HIVE_KEY" -o StrictHostKeyChecking=no "$HIVE_USER@$HIVE_HOST" \
  'cat >> ~/.ssh/config << SSHCONFIG
Host trino-container
    HostName ${TRINO_HOST}
    User datalake
    IdentityFile ~/.ssh/id_trino
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
SSHCONFIG' 

echo ""
echo "=== NEXT STEPS ==="
echo ""
echo "From Hive container, you can now test:"
echo "  ssh -i ~/.ssh/id_trino datalake@192.168.4.35 'echo test'"
echo ""
echo "To add this key to Trino authorized_keys:"
echo "  1. Setup password-less sudo on Trino, OR"
echo "  2. Use this script to add via Proxmox pct"
echo ""





