#!/usr/bin/env bash
# Run this on Proxmox host as root to add the canonical public key to CTs
# It appends the public key to datalake's authorized_keys inside each CT.

PUB='$(cat scripts/key/ct_datalake_id_ed25519.pub)'
CTS=(107 108 109 111 115 116 117 118)
for ct in "${CTS[@]}"; do
  echo "Applying key to CT $ct"
  pct exec $ct -- su - datalake -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo \"$PUB\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done

echo "Done. Verify by checking 'pct exec <ct> -- su - datalake -c \"cat ~/.ssh/authorized_keys\"'"
