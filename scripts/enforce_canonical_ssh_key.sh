#!/usr/bin/env bash
set -euo pipefail

PROXMOX="${PROXMOX_HOST:-}"
CTS="${CT_IDS:-}"
PUB_KEY="${PUB_KEY_PATH:-scripts/key/ct_datalake_id_ed25519.pub}"
SSH_USER="${SSH_USER:-datalake}"
SSH_OPTS="${SSH_OPTS:-}" # ex.: -i ~/.ssh/id_ed25519

usage() {
  cat <<'EOF'
Uso: enforce_canonical_ssh_key.sh --proxmox root@HOST --cts "107 108" [--pub-key caminho] [--user datalake] [--ssh-opts "-i ~/.ssh/id_ed25519"]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox) PROXMOX="$2"; shift 2 ;;
    --cts) CTS="$2"; shift 2 ;;
    --pub-key) PUB_KEY="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    --ssh-opts) SSH_OPTS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Parametro desconhecido: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$PROXMOX" || -z "$CTS" ]]; then
  echo "Defina --proxmox e --cts (ou variaveis PROXMOX_HOST e CT_IDS)." >&2
  usage
  exit 1
fi

if [[ ! -f "$PUB_KEY" ]]; then
  echo "Chave publica nao encontrada: $PUB_KEY" >&2
  exit 1
fi

PUB_CONTENT="$(<"$PUB_KEY")"

for ct in $CTS; do
  echo "==== CT $ct ===="
  printf '%s\n' "$PUB_CONTENT" |
    ssh $SSH_OPTS "$PROXMOX" "pct exec $ct -- bash -lc 'set -euo pipefail; umask 077; mkdir -p /home/$SSH_USER/.ssh; cat > /home/$SSH_USER/.ssh/authorized_keys; chmod 700 /home/$SSH_USER/.ssh; chmod 600 /home/$SSH_USER/.ssh/authorized_keys; chown -R $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh'"
  echo "Aplicado em CT $ct"
  echo
done
