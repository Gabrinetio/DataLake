#!/usr/bin/env bash
set -euo pipefail

# Teste rápido para Kafka: verifica porta 9092, lista tópicos e produz/consome uma mensagem

KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
BOOTSTRAP=${BOOTSTRAP:-localhost:9092}
TOPIC=${TOPIC:-cdc.vendas}

echo "== Test Kafka =="

if [ ! -x "${KAFKA_HOME}/bin/kafka-topics.sh" ]; then
  echo "Kafka binaries not found under ${KAFKA_HOME}"; exit 2
fi

echo "Checking port 9092"
ss -tlnp | grep :9092 || true

echo "Listing topics"
${KAFKA_HOME}/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP --list

echo "Producing test message"
echo "test-kafka-$(date +%s)" | ${KAFKA_HOME}/bin/kafka-console-producer.sh --bootstrap-server $BOOTSTRAP --topic $TOPIC

echo "Consuming one message from topic"
${KAFKA_HOME}/bin/kafka-console-consumer.sh --bootstrap-server $BOOTSTRAP --topic $TOPIC --from-beginning --max-messages 1

echo "Kafka smoke test done"
exit 0
