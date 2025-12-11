#!/bin/bash

# Script para configurar MinIO após instalação

set -e

echo "=== Configuração do MinIO ==="

# Mover arquivos de configuração
sudo mv /tmp/minio.env /etc/default/minio
sudo chmod 600 /etc/default/minio

sudo mv /tmp/minio.service /etc/systemd/system/minio.service
sudo chmod 644 /etc/systemd/system/minio.service

# Recarregar systemd e iniciar MinIO
sudo systemctl daemon-reload
sudo systemctl enable --now minio

echo "MinIO configurado e iniciado. Status:"
sudo systemctl status minio --no-pager

echo "Console MinIO: http://minio.gti.local:9001"
echo "API S3: http://minio.gti.local:9000"