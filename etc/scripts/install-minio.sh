#!/bin/bash

# Script de instalação do MinIO no CT minio.gti.local
# Baseado em docs/MinIO_Implementacao.md

set -e

echo "=== Instalação do MinIO ==="

# Atualizar sistema
echo "Atualizando sistema..."
apt update && apt upgrade -y
apt install -y wget curl vim jq

# Baixar MinIO e mc
echo "Baixando MinIO e mc..."
wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
chmod +x /usr/local/bin/minio

wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
chmod +x /usr/local/bin/mc

# Preparar diretórios e usuário
echo "Preparando diretórios..."
mkdir -p /data/minio
chown -R datalake:datalake /data/minio

mkdir -p /etc/minio
chown -R datalake:datalake /etc/minio

# Configurar sudo sem senha para datalake
echo "Configurando sudo para datalake..."
echo 'datalake ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/datalake
chmod 440 /etc/sudoers.d/datalake

echo "Instalação básica concluída. Execute como datalake: sudo systemctl daemon-reload && sudo systemctl enable --now minio"