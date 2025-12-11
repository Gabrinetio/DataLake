#!/usr/bin/env bash
set -euo pipefail

# deploy-spark-systemd.sh
# Copia os templates de systemd para /etc/systemd/system, recarrega daemon e habilita unidades

TEMPLATE_DIR="$(dirname "$0")/../systemd"
mkdir -p /etc/systemd/system

echo "Copiando templates..."
cp -v "$TEMPLATE_DIR/spark-master.service.template" /etc/systemd/system/spark-master.service
cp -v "$TEMPLATE_DIR/spark-worker.service.template" /etc/systemd/system/spark-worker.service

systemctl daemon-reload
systemctl enable --now spark-master || true
systemctl enable --now spark-worker || true

echo "Unidades spark-master e spark-worker habilitadas (se compatíveis com o ambiente atual)."

exit 0
