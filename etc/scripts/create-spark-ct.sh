#!/usr/bin/env bash
set -euo pipefail

# create-spark-ct.sh
# Automatiza a criação do container LXC para Spark no Proxmox e faz o provisionamento básico
# Uso: create-spark-ct.sh [--vmid 103] [--hostname spark.gti.local] [--ip 192.168.4.33/24] [--bridge vmbr0] [--storage local-lvm] [--template local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz] [--cores 4] [--memory 8192] [--disk 40] [--unprivileged 1] [--nesting 1] [--ssh-key /path/to/key.pub] [--dry-run]

SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
DRY_RUN=0
VMID=103
HOSTNAME="spark.gti.local"
IP="192.168.4.33/24"
GATEWAY="192.168.4.1"
BRIDGE="vmbr0"
STORAGE=${STORAGE:-local}
TEMPLATE=${TEMPLATE:-local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz}
CORES=4
MEMORY=8192
DISK=40
UNPRIVILEGED=1
NESTING=1
SSH_KEY=""
KEY_NAME="datalake"

if command -v pct >/dev/null 2>&1; then
  PCT_AVAILABLE=1
else
  PCT_AVAILABLE=0
fi

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY_RUN: $*"
  else
    echo "+ $*"
    eval "$*"
  fi
}
ROOTFS_OPTS="${STORAGE}:$DISK"

echo "Criando CT Spark: vmid=$VMID hostname=$HOSTNAME ip=$IP cores=$CORES memory=${MEMORY}MB disk=${DISK}GB template=$TEMPLATE"

if [ "$PCT_AVAILABLE" -eq 0 ]; then
  echo "Proxmox 'pct' não encontrado: imprimindo sequência de comandos que você deve executar no host Proxmox. Use --dry-run se quiser apenas inspecionar."
  DRY_RUN=1
fi

# 1) Criar o container
CMD="pct create $VMID $TEMPLATE --hostname $HOSTNAME --cores $CORES --memory $MEMORY --net0 $PCT_NET --rootfs $ROOTFS_OPTS --unprivileged $UNPRIVILEGED"
if [ "$NESTING" -eq 1 ]; then
  CMD="$CMD --features nesting=1"
fi
run_cmd "$CMD"

# 2) Iniciar CT
run_cmd "pct start $VMID"

# 3) Opcional: push scripts e executar provisionamento
FILES_TO_PUSH=(install-spark.sh configure-spark.sh deploy-spark-systemd.sh setup_datalake_remote.sh spark.env.example)

for f in "${FILES_TO_PUSH[@]}"; do
  SRC="$SCRIPT_DIR/$(basename "$f")"
  if [ -f "$SRC" ]; then
    DEST="/tmp/$(basename "$f")"
    run_cmd "pct push $VMID $SRC $DEST"
  else
    echo "AVISO: arquivo $SRC não encontrado; ignorando push" >&2
  fi
done

# 4) Criar usuário datalake e instalar chave pública (se fornecida)
if [ "$GEN_KEY" -eq 1 ]; then
  # generate key locally
  TMP_KEY_PREFIX=$(mktemp -u /tmp/datalake_key_XXXX)
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY_RUN: ssh-keygen -t ed25519 -f ${TMP_KEY_PREFIX} -N ''"
  else
    ssh-keygen -t ed25519 -f "$TMP_KEY_PREFIX" -N "" -q
  fi
  if [ -n "$OUT_PRIVATE" ]; then
    if [ -f "$OUT_PRIVATE" ] && [ "$FORCE" -ne 1 ]; then
      echo "Arquivo $OUT_PRIVATE já existe. Use --force para sobrescrever." >&2
      exit 2
    fi
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "DRY_RUN: mv -f $TMP_KEY_PREFIX $OUT_PRIVATE"
      else
        mv -f "$TMP_KEY_PREFIX" "$OUT_PRIVATE"
        mv -f "${TMP_KEY_PREFIX}.pub" "${OUT_PRIVATE}.pub" 2>/dev/null || true
      fi
    chmod 600 "$OUT_PRIVATE" || true
    SSH_KEY="$OUT_PRIVATE"
  else
    SSH_KEY="$TMP_KEY_PREFIX"
  fi
fi

  # Cleanup generated tmp keys if not preserved
  if [ "${TMP_KEY_PREFIX_GENERATED:-0}" -eq 1 ]; then
    rm -f "${TMP_KEY_PREFIX}" "${TMP_KEY_PREFIX}.pub" || true
  fi

if [ -n "$SSH_KEY" ]; then
  # Determine public key path: if SSH_KEY ends with .pub, use it; else try SSH_KEY.pub
  if [ "$DRY_RUN" -eq 1 ]; then
    PUBKEY_CONTENT="DRY_RUN-PUBLIC-KEY"
  else
    if [[ "$SSH_KEY" == *.pub ]] && [ -f "$SSH_KEY" ]; then
      PUBKEY_CONTENT="$(cat "$SSH_KEY")"
    elif [ -f "${SSH_KEY}.pub" ]; then
      PUBKEY_CONTENT="$(cat "${SSH_KEY}.pub")"
    elif [ -f "$SSH_KEY" ]; then
      PUBKEY_CONTENT="$(ssh-keygen -y -f "$SSH_KEY")"
    else
      PUBKEY_CONTENT=""
    fi
  fi
  TMPFILE="/tmp/datalake_pubkey"
  echo "$PUBKEY_CONTENT" >/tmp/tmp_datalake_pubkey || true
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY_RUN: pct push $VMID /tmp/tmp_datalake_pubkey $TMPFILE"
    echo "DRY_RUN: pct exec $VMID -- bash -lc 'bash /tmp/setup_datalake_remote.sh'"
  else
    run_cmd "pct push $VMID /tmp/tmp_datalake_pubkey $TMPFILE"
    run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/setup_datalake_remote.sh'"
  fi
  rm -f /tmp/tmp_datalake_pubkey || true
fi

# 5) Executar provisionamento: update, install spark, configure spark, deploy systemd
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY_RUN: provisionando dentro do container... (apt update, apt install, instalar spark)"
else
  run_cmd "pct exec $VMID -- bash -lc 'apt update && apt upgrade -y && apt install -y sudo curl wget tar default-jdk python3 python3-venv python3-pip git vim'"
  run_cmd "pct exec $VMID -- bash -lc 'mkdir -p /tmp/provision && cd /tmp/provision && bash /tmp/install-spark.sh'"
  run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/configure-spark.sh'"
  run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/deploy-spark-systemd.sh'"
fi

echo "Script finalizado. Se não estiver em modo dry-run, o container $VMID/$HOSTNAME deve estar criado e com Spark provisionado (no mínimo)."

exit 0
