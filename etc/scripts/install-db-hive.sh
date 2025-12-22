#!/bin/bash

# Script de instalação do DB Hive (MariaDB + Hive Metastore)

set -euo pipefail

echo "=== Instalação do DB Hive ==="

# Carrega env (opcional) para variáveis como HIVE_DB_PASSWORD
ENV_FILE=""
if [ -f /etc/hive/hive.env ]; then
	ENV_FILE=/etc/hive/hive.env
elif [ -f "$(dirname "$0")/hive.env" ]; then
	ENV_FILE="$(dirname "$0")/hive.env"
elif [ -f ".env" ]; then
	ENV_FILE=".env"
fi
if [ -n "$ENV_FILE" ]; then
	echo "Carregando variáveis de $ENV_FILE"
	set -a; . "$ENV_FILE"; set +a
fi

# Defaults
HIVE_DB_NAME=${HIVE_DB_NAME:-metastore}
HIVE_DB_USER=${HIVE_DB_USER:-hive}
HIVE_DB_PASSWORD=${HIVE_DB_PASSWORD:-"<<SENHA_FORTE>>"}  # Use Vault/variável de ambiente

# Atualizar sistema
apt update && apt upgrade -y
apt install -y wget curl vim jq mariadb-server

# Iniciar MariaDB
systemctl enable --now mariadb

# Configurar usuário hive do SO (para executar processos do Hive e ownership de arquivos)
if ! id -u hive >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" hive
	usermod -aG sudo hive || true
	echo 'hive ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/hive
	chmod 440 /etc/sudoers.d/hive
fi

# Criar banco e usuário no MariaDB
echo "Criando banco e usuário do metastore (MariaDB)"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $HIVE_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "GRANT ALL PRIVILEGES ON $HIVE_DB_NAME.* TO \"$HIVE_DB_USER\"@\"localhost\" IDENTIFIED BY \"$HIVE_DB_PASSWORD\"; FLUSH PRIVILEGES;"

echo "Instalação básica concluída. Banco '$HIVE_DB_NAME' e usuário '$HIVE_DB_USER' criados."