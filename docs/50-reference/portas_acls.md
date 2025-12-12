# Portas e ACLs

## Portas principais (produção)
- MariaDB (Metastore): 3306 — Origem: Hive/Spark/Trino
- Hive Thrift: 10000 — Origem: Spark/Trino
- Spark Master RPC: 7077 — Origem: nós Spark Worker
- Spark UI: 8080 (Master), 8081+ (Workers) — Origem: Ops (jump/bastion)
- MinIO: 9000 (API), 9001 (Console) — Origem: Spark/Hive/Trino/Ops
- Kafka: 9092 — Origem: produtores/consumidores autorizados
- Trino: 8080 — Origem: BI/Ops
- Grafana: 3000 — Origem: Ops
- Prometheus: 9090 — Origem: Ops

## Regras sugeridas
- Permitir apenas IPs internos/vpn para UIs (Spark, MinIO Console, Grafana/Prometheus).
- Bloquear acesso externo direto a Kafka/Hive/Metastore; uso via rede interna.
- Preferir autenticação/TLS onde suportado (MinIO/Trino/Grafana).
- Registrar mudanças em firewall (ufw/iptables/SG) por ambiente.
