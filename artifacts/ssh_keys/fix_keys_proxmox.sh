#!/usr/bin/env bash
# fix_keys_proxmox.sh
# Uso (no host Proxmox como root):
#   cat /path/to/ct_datalake_id_ed25519.pub | bash fix_keys_proxmox.sh
# ou
#   bash fix_keys_proxmox.sh /path/to/ct_datalake_id_ed25519.pub

set -euo pipefail
DATE=$(date +%Y%m%d_%H%M%S)
OUTDIR="/root/artifacts/ssh_keys/backups/$DATE"
mkdir -p "$OUTDIR"
DRY_RUN=false
PUBFILE=""

if [ "$#" -ge 1 ]; then
  PUBFILE="$1"
fi

if [ -t 0 ] && [ -z "$PUBFILE" ]; then
  echo "Error: provide public key via stdin or as first arg" >&2
  echo "Usage: cat key.pub | bash fix_keys_proxmox.sh   OR   bash fix_keys_proxmox.sh /path/key.pub" >&2
  exit 1
fi

if [ -n "$PUBFILE" ]; then
  if [ ! -f "$PUBFILE" ]; then
    echo "Public key file not found: $PUBFILE" >&2
    exit 1
  fi
  PUB=$(cat "$PUBFILE")
else
  PUB=$(cat -)
fi

CTS=(107 108 109 111 115 116 117 118)

# Ensure running as root
if [ $(id -u) -ne 0 ]; then
  echo "This script must be run as root on the Proxmox host" >&2
  exit 1
fi

for ct in "${CTS[@]}"; do
  echo "--- Processing CT $ct ---"
  bak="$OUTDIR/ct_${ct}_authorized_keys.bak"

  # fetch current authorized_keys (if any)
  if pct exec $ct -- su - datalake -c 'cat ~/.ssh/authorized_keys' > "$bak" 2>/dev/null; then
    echo "Saved backup to $bak"
  else
    echo "No authorized_keys found or unable to fetch; creating empty backup file"
    printf "" > "$bak"
  fi

  # upload pub key into CT tmp file
  pct exec $ct -- su - datalake -c "cat > /tmp/ct_key.pub <<'KEY'\n$PUB\nKEY" || { echo "Failed to write temp key on CT $ct"; continue; }

  # check if key already present
  if pct exec $ct -- su - datalake -c "grep -Fx -f /tmp/ct_key.pub ~/.ssh/authorized_keys >/dev/null 2>&1 || true"; then
    # grep returns non-zero when not found; we check via exit codes
    if pct exec $ct -- su - datalake -c "grep -Fx -f /tmp/ct_key.pub ~/.ssh/authorized_keys >/dev/null 2>&1"; then
      echo "Key already present on CT $ct"
      pct exec $ct -- su - datalake -c "rm -f /tmp/ct_key.pub"
      continue
    fi
  fi

  echo "Appending key to CT $ct authorized_keys"
  pct exec $ct -- su - datalake -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && cat /tmp/ct_key.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chown -R datalake:datalake ~/.ssh && rm -f /tmp/ct_key.pub"

  # ensure sshd allows pubkey (try to set and restart if needed)
  pct exec $ct -- su - datalake -c "grep -E '^\s*PubkeyAuthentication' /etc/ssh/sshd_config || true" >/dev/null 2>&1 || true
  # try enabling if disabled
  pct exec $ct -- bash -lc "if grep -E '^\s*PubkeyAuthentication\s+no' /etc/ssh/sshd_config >/dev/null 2>&1; then sed -i 's/^\s*PubkeyAuthentication\s\+no/\nPubkeyAuthentication yes/' /etc/ssh/sshd_config || true; fi" || true
  # restart ssh if systemctl exists
  pct exec $ct -- bash -lc "(systemctl restart ssh || systemctl restart sshd) >/dev/null 2>&1 || true" || true

  echo "CT $ct: key appended and permissions set. Backup at $bak"
  echo
done

echo "All done. Backups stored in $OUTDIR"