#!/usr/bin/env bash
set -euo pipefail

# create-kafka-ct.sh
# Automatiza a criação do container LXC para Kafka no Proxmox e faz o provisionamento básico
# Uso: create-kafka-ct.sh [--vmid 104] [--hostname kafka.gti.local] [--ip 192.168.4.34/24] [--bridge vmbr0] [--storage local-lvm] [--template local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz] [--cores 2] [--memory 4096] [--disk 20] [--unprivileged 1] [--nesting 1] [--ssh-key /path/to/key.pub] [--dry-run]

SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
DRY_RUN=0
VMID=109
HOSTNAME="kafka.gti.local"
IP="192.168.4.34/24"
GATEWAY="192.168.4.1"
BRIDGE="vmbr0"
STORAGE=${STORAGE:-local}
TEMPLATE=${TEMPLATE:-local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz}
CORES=2
MEMORY=4096
DISK=20
UNPRIVILEGED=1
NESTING=1
SSH_KEY=""
PCT_NET="name=eth0,bridge=${BRIDGE},ip=${IP},gw=${GATEWAY}"

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

echo "Criando CT Kafka: vmid=$VMID hostname=$HOSTNAME ip=$IP cores=$CORES memory=${MEMORY}MB disk=${DISK}GB template=$TEMPLATE"

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

# 3) push scripts e executar provisionamento (se existirem)
FILES_TO_PUSH=(install-kafka.sh configure-kafka.sh deploy-kafka-systemd.sh create-kafka-topics.sh)

for f in "${FILES_TO_PUSH[@]}"; do
  SRC="$SCRIPT_DIR/$(basename "$f")"
  if [ -f "$SRC" ]; then
    DEST="/tmp/$(basename "$f")"
    run_cmd "pct push $VMID $SRC $DEST"
  else
    echo "AVISO: arquivo $SRC não encontrado; ignorando push" >&2
  fi
done

# 4) Instalar e provisionar Kafka
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY_RUN: provisionando dentro do container... (apt update, apt install, instalar kafka)"
else
  run_cmd "pct exec $VMID -- bash -lc 'apt update && apt upgrade -y && apt install -y openjdk-17-jdk wget curl jq net-tools lsb-release gnupg'"
  run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/install-kafka.sh'"
  run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/deploy-kafka-systemd.sh'"
  run_cmd "pct exec $VMID -- bash -lc 'bash /tmp/create-kafka-topics.sh'"
fi

echo "Script finalizado. Se não estiver em modo dry-run, o container $VMID/$HOSTNAME deve estar criado e com Kafka provisionado (no mínimo)."

exit 0



