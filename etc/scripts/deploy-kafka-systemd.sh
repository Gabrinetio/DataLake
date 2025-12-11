#!/usr/bin/env bash
set -euo pipefail

# deploy-kafka-systemd.sh
# Copia a unidade systemd template para o host e habilita o serviço

UNIT_TEMPLATE="/etc/systemd/system/kafka.service"
TEMPLATE_SRC_DIR="$(dirname "${BASH_SOURCE[0]}")"

if [ ! -f "$TEMPLATE_SRC_DIR/../systemd/kafka.service.template" ]; then
  echo "Template kafka.service.template não encontrado em etc/systemd", exit 1
fi

echo "Instalando unit systemd kafka..."
cp "$TEMPLATE_SRC_DIR/../systemd/kafka.service.template" "$UNIT_TEMPLATE"
chmod 644 "$UNIT_TEMPLATE"
systemctl daemon-reload
systemctl enable --now kafka

echo "Kafka service deployed and started (systemctl status kafka)."

exit 0
