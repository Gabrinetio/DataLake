#!/usr/bin/env bash
set -euo pipefail

# create-kafka-topics.sh
# Cria tópicos iniciais em Kafka (KRaft single-node)

KAFKA_HOME=${KAFKA_HOME:-/opt/kafka}
BOOTSTRAP=${BOOTSTRAP:-localhost:9092}

echo "Aguardando Kafka boot (10s)..."
sleep 10

TOPICS=(
  "cdc.vendas:3:1"
  "cdc.events:3:1"
  "connect-offsets:1:1"
)

for t in "${TOPICS[@]}"; do
  IFS=":" read -r name partitions rf <<< "$t"
  echo "Criando tópico: $name (partitions=$partitions, rf=$rf)"
  $KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP --create --topic "$name" --partitions $partitions --replication-factor $rf || true
done

echo "Listando tópicos"
$KAFKA_HOME/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP --list

echo "Tópicos criados."
exit 0
