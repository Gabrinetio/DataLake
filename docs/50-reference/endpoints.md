# Endpoints e URLs de Serviço

Adapte os hosts conforme o ambiente (produção, staging, lab). Evite colocar senhas aqui.

## Produção (configuração atual - 12/12/2025)
- Spark Master RPC: `spark://192.168.4.33:7077`
- Spark Master UI: `http://192.168.4.33:8080`
- Hive Metastore (JDBC): `jdbc:hive2://192.168.4.32:9083`
- MinIO:
  - API S3: `http://192.168.4.31:9000`
  - Console Web: `http://192.168.4.31:9001`
- Trino: `http://192.168.4.35:8080`
- Superset (BI): CT 115 @ `192.168.4.37` (NÃO EXPOSTO - somente SSH:22)
  - PostgreSQL: `postgresql://postgres@localhost/postgres` (local no CT 115)
  - Driver: `psycopg2-binary` ✅ instalado
- Airflow: `http://192.168.4.36:8089` (Webserver), `192.168.4.36:8793` (Scheduler)
- Kafka Broker: `192.168.4.34:9092`, `192.168.4.34:9093`
- Gitea: `http://192.168.4.26:3000`

## Observações
- Atualize estes valores se houver mudança de IP ou DNS; reflita nos scripts de deploy e nos runbooks.
- Padronize nomes de host (ex.: `spark.prod.datalake.local`) quando o DNS interno estiver disponível.
