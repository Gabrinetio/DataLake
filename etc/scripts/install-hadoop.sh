#!/usr/bin/env bash
set -euo pipefail

# install-hadoop.sh
# Instala o Apache Hadoop para suporte ao Hive Metastore
# Uso: install-hadoop.sh [HADOOP_VERSION]

HADOOP_VERSION=${1:-${HADOOP_VERSION:-3.3.6}}
HADOOP_DOWNLOAD_BASE=${HADOOP_DOWNLOAD_BASE:-https://downloads.apache.org/hadoop/common}
HADOOP_ARCHIVE="hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_URL="$HADOOP_DOWNLOAD_BASE/hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE}"
HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
HADOOP_USER=${HADOOP_USER:-hadoop}
HADOOP_GROUP=${HADOOP_GROUP:-hadoop}
JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}

echo "Instalando Apache Hadoop $HADOOP_VERSION no $HADOOP_HOME"

apt-get update && apt-get install -y wget curl tar || true

# Criar usuário hadoop se não existir
if ! id -u "$HADOOP_USER" >/dev/null 2>&1; then
  adduser --system --home "$HADOOP_HOME" --group "$HADOOP_USER" || true
fi

mkdir -p /tmp/hadoop-install
cd /tmp/hadoop-install

echo "Baixando Hadoop: $HADOOP_URL"
rm -f "$HADOOP_ARCHIVE"
wget "$HADOOP_URL" -O "$HADOOP_ARCHIVE" || { echo "Falha no download"; exit 1; }

HADOOP_EXTRACTED_DIR="hadoop-${HADOOP_VERSION}"
rm -rf "$HADOOP_EXTRACTED_DIR"
tar -xzf "$HADOOP_ARCHIVE"

rm -rf "$HADOOP_HOME"
mv "$HADOOP_EXTRACTED_DIR" "$HADOOP_HOME"
chown -R "$HADOOP_USER:$HADOOP_GROUP" "$HADOOP_HOME"

# Configurar ambiente básico
cat > /etc/profile.d/hadoop.sh <<EOF
export HADOOP_HOME=$HADOOP_HOME
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF

echo "Hadoop instalado com sucesso em $HADOOP_HOME"
echo "Para usar, execute: source /etc/profile.d/hadoop.sh"