#!/usr/bin/env bash
set -euo pipefail

# install-kafka.sh
# Instala Apache Kafka (KRaft mode) em single-node para ambiente de desenvolvimento/testes
# Uso: install-kafka.sh [KAFKA_VERSION]

KAFKA_VERSION=${1:-3.5.1}
KAFKA_BASE=${KAFKA_BASE:-/opt/kafka}
KAFKA_USER=${KAFKA_USER:-kafka}
KAFKA_GROUP=${KAFKA_GROUP:-kafka}
KAFKA_DOWNLOAD_BASE=${KAFKA_DOWNLOAD_BASE:-https://downloads.apache.org/kafka}
KAFKA_ARCHIVE="kafka_2.13-${KAFKA_VERSION}.tgz"
KAFKA_URL="$KAFKA_DOWNLOAD_BASE/${KAFKA_VERSION}/$KAFKA_ARCHIVE"

echo "=== Install Kafka $KAFKA_VERSION (KRaft mode) ==="

# Install dependencies
apt-get update || true
apt-get install -y openjdk-17-jdk wget curl jq || true

# Create user and group
if ! id -u $KAFKA_USER >/dev/null 2>&1; then
  adduser --system --group --no-create-home --shell /bin/false $KAFKA_USER || true
fi

# Download and extract
TMPDIR=$(mktemp -d)
pushd $TMPDIR >/dev/null
if [ ! -f "$KAFKA_ARCHIVE" ]; then
  echo "Baixando Kafka: $KAFKA_URL"
  wget -q "$KAFKA_URL" -O "$KAFKA_ARCHIVE"
fi
tar -xzf "$KAFKA_ARCHIVE"
KAFKA_EXTRACTED_DIR=$(tar -tf "$KAFKA_ARCHIVE" | head -n1 | cut -f1 -d"/")

rm -rf $KAFKA_BASE
mv "$KAFKA_EXTRACTED_DIR" "$KAFKA_BASE"
chown -R $KAFKA_USER:$KAFKA_GROUP $KAFKA_BASE

# KRaft config (single node)
echo "Configuring Kafka (KRaft single-node)"
mkdir -p $KAFKA_BASE/data
chown $KAFKA_USER:$KAFKA_GROUP $KAFKA_BASE/data

cat > $KAFKA_BASE/config/kraft/server.properties <<'EOF'
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093
listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
inter.broker.listener.name=PLAINTEXT
log.dirs=/opt/kafka/data/kraft-logs
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
controller.listener.names=CONTROLLER
EOF

mkdir -p /opt/kafka/data/kraft-logs
chown -R $KAFKA_USER:$KAFKA_GROUP /opt/kafka/data

echo "Criando environment wrapper scripts"
cat > /usr/local/bin/kafka-start <<'EOF'
#!/usr/bin/env bash
export KAFKA_HOME=/opt/kafka
exec /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server.properties
EOF
chmod +x /usr/local/bin/kafka-start
chown $KAFKA_USER:$KAFKA_GROUP /usr/local/bin/kafka-start

echo "Kafka instalado em $KAFKA_BASE"

popd >/dev/null
rm -rf $TMPDIR

echo "Instalação concluída. Execute o deploy systemd para iniciar o serviço."
exit 0
