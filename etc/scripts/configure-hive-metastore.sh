#!/bin/bash

# Script para configurar Hive Metastore (lê variáveis de /etc/hive/hive.env, etc/scripts/hive.env, ou .env)

set -euo pipefail

echo "=== Configuração do Hive Metastore ==="

# Carrega arquivo de variáveis em ordem de prioridade:
# 1. /etc/hive/hive.env
# 2. etc/scripts/hive.env (no repositório)
# 3. .env (local)
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
  # exporta todas as variáveis lidas
  set -a; . "$ENV_FILE"; set +a
fi

# Defaults
HIVE_DB_HOST=${HIVE_DB_HOST:-localhost}
HIVE_DB_PORT=${HIVE_DB_PORT:-3306}
HIVE_DB_NAME=${HIVE_DB_NAME:-metastore}
HIVE_DB_USER=${HIVE_DB_USER:-hive}
HIVE_DB_PASSWORD=${HIVE_DB_PASSWORD:-"<<SENHA_FORTE>>"}  # Use Vault/variável de ambiente
HIVE_INIT_SCHEMA=${HIVE_INIT_SCHEMA:-true}
HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}
HIVE_HOME=${HIVE_HOME:-/opt/hive}

# Download do Hive se necessário
if [ ! -d "$HIVE_HOME" ]; then
  wget -nc https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz
  tar -xzf apache-hive-3.1.3-bin.tar.gz -C /opt
  ln -sf /opt/apache-hive-3.1.3-bin /opt/hive
fi

# Configurar ambiente
export HIVE_HOME="$HIVE_HOME"
export PATH="$PATH:$HIVE_HOME/bin"

CONNECTION_URL="jdbc:mariadb://$HIVE_DB_HOST:$HIVE_DB_PORT/$HIVE_DB_NAME"
DRIVER_CLASS="org.mariadb.jdbc.Driver"

echo "Criando / atualizando /opt/hive/conf/hive-site.xml"
mkdir -p /opt/hive/conf
cat > /opt/hive/conf/hive-site.xml <<EOF
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>$CONNECTION_URL</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>$DRIVER_CLASS</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>$HIVE_DB_USER</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>$HIVE_DB_PASSWORD</value>
  </property>
</configuration>
EOF

# Baixar driver MariaDB (se não existir ou for diferente)
mkdir -p /opt/hive/lib
if [ ! -s /opt/hive/lib/mariadb-java-client.jar ]; then
  wget -q -O /opt/hive/lib/mariadb-java-client.jar https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/3.1.4/mariadb-java-client-3.1.4.jar
fi

echo "Configuração concluída."

# Inicializar schema opcionalmente
if [ "$HIVE_INIT_SCHEMA" = "true" ] || [ "$HIVE_INIT_SCHEMA" = "1" ]; then
  echo "Inicializando schema do Hive Metastore (schematool -dbType mysql -initSchema)"
  if id -u hive >/dev/null 2>&1; then
    # Executa como usuário hive assegurando HADOOP_HOME e JAVA_HOME
    sudo -u hive env HADOOP_HOME="$HADOOP_HOME" JAVA_HOME="$JAVA_HOME" PATH="$PATH" /opt/hive/bin/schematool -dbType mysql -initSchema
  else
    echo "Usuário hive não encontrado. Inicialize o schema manualmente como hive: schematool -dbType mysql -initSchema"
  fi
fi