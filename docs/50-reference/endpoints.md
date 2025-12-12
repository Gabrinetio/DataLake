# Endpoints e URLs de Serviço

Adapte os hosts conforme o ambiente (produção, staging, lab). Evite colocar senhas aqui.

## Produção (exemplo atual)
- Spark Master RPC: `spark://192.168.4.33:7077`
- Spark Master UI: `http://192.168.4.33:8080`
- Hive Metastore (JDBC): `jdbc:hive2://192.168.4.33:10000`
- MinIO:
  - API S3: `http://192.168.4.33:9000`
  - Console Web: `http://192.168.4.33:9001`
- Trino: `http://192.168.4.33:8080`
- Grafana: `http://192.168.4.33:3000`
- Prometheus: `http://192.168.4.33:9090`
- Kafka Broker: `192.168.4.33:9092`

## Observações
- Atualize estes valores se houver mudança de IP ou DNS; reflita nos scripts de deploy e nos runbooks.
- Padronize nomes de host (ex.: `spark.prod.datalake.local`) quando o DNS interno estiver disponível.
