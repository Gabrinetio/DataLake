#!/usr/bin/env bash
set -euo pipefail

# configure-kafka.sh
# Configurações adicionais do Kafka (ex.: /etc/hosts entry, usuário, firewall)

KAFKA_USER=${KAFKA_USER:-kafka}
HOSTNAME=${HOSTNAME:-kafka.gti.local}

echo "Configuração básica do Kafka"

# garantir entrada /etc/hosts (somente se não existir)
if ! grep -q "${HOSTNAME}" /etc/hosts 2>/dev/null; then
  echo "192.168.4.32 ${HOSTNAME}" >> /etc/hosts
fi

# Criar usuário kafka se não existir
if ! id -u $KAFKA_USER >/dev/null 2>&1; then
  adduser --system --group --no-create-home --shell /bin/false $KAFKA_USER || true
fi

echo "Configuração concluída."
exit 0



