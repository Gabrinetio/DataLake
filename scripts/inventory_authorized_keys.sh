#!/usr/bin/env bash
# Inventaria arquivos authorized_keys dos CTs e salva em artifacts/ssh_keys/
# Uso: ./inventory_authorized_keys.sh [--proxmox-host <host>] [--proxmox-pass <pass>] [--dry-run]

set -euo pipefail
PROXMOX_HOST=${PROXMOX_HOST:-192.168.4.25}
PROXMOX_PASS=${PROXMOX_PASS:-}
DRY_RUN=false
KEY_PRIVATE=${KEY_PRIVATE:-scripts/key/ct_datalake_id_ed25519}  # recomendado: usar chave canônica do projeto (padrão)
USER=${USER:-datalake}
OUTDIR="$(dirname "$0")/../artifacts/ssh_keys"
mkdir -p "$OUTDIR"

declare -A CTHOSTS=(
  [117]=db-hive.gti.local
  [107]=minio.gti.local
  [108]=spark.gti.local
  [109]=kafka.gti.local
  [111]=trino.gti.local
  [115]=superset.gti.local
  [116]=airflow.gti.local
  [118]=gitea.gti.local
)

while [[ $# -gt 0 ]]; do
  case $1 in
    --proxmox-host) PROXMOX_HOST="$2"; shift 2;;
    --proxmox-pass) PROXMOX_PASS="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --key) KEY_PRIVATE="$2"; shift 2;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

for ct in "${!CTHOSTS[@]}"; do
  host=${CTHOSTS[$ct]}
  out="$OUTDIR/ct_${ct}_${host}_authorized_keys.txt"
  echo "=== CT $ct ($host) ===" > "$out"

  if $DRY_RUN; then
    echo "DRY RUN - would check direct SSH to $host and fallback to Proxmox" >> "$out"
    echo "SKIPPED" >> "$out"
    continue
  fi

  # Try direct SSH first
  if ssh -i "$KEY_PRIVATE" -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$host" 'echo OK' &>/dev/null; then
    echo "method: direct_ssh" >> "$out"
    ssh -i "$KEY_PRIVATE" -o StrictHostKeyChecking=no "$USER@$host" 'cat ~/.ssh/authorized_keys || true' >> "$out" 2>&1 || true
    echo "done" >> "$out"
    continue
  fi

  # Fallback: use Proxmox pct exec if PROXMOX_PASS available
  if [[ -n "$PROXMOX_PASS" ]] && command -v sshpass &>/dev/null; then
    echo "method: proxmox_pct_exec" >> "$out"
    sshpass -p "$PROXMOX_PASS" ssh -o StrictHostKeyChecking=no root@"$PROXMOX_HOST" "pct exec $ct -- su - datalake -c 'cat ~/.ssh/authorized_keys'" >> "$out" 2>&1 || true
    echo "done (via proxmox)" >> "$out"
    continue
  fi

  echo "UNABLE_TO_FETCH: direct SSH failed and no proxmox credentials" >> "$out"
done

echo "Inventory complete, results in $OUTDIR"