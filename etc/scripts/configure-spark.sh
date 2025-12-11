#!/usr/bin/env bash
set -euo pipefail

# configure-spark.sh
# Configura o Spark para se integrar com Hive Metastore e MinIO
# Lê variáveis de /etc/spark/spark.env, etc/scripts/spark.env, ou .env (mesma lógica do Hive)

echo "=== Configuração do Spark ==="

# Carrega arquivo de variáveis em ordem de prioridade (igual ao do Hive)
ENV_FILE=""
if [ -f /etc/spark/spark.env ]; then
  ENV_FILE=/etc/spark/spark.env
elif [ -f "$(dirname "$0")/spark.env" ]; then
  ENV_FILE="$(dirname "$0")/spark.env"
elif [ -f ".env" ]; then
  ENV_FILE=.env
fi

if [ -n "$ENV_FILE" ]; then
  echo "Carregando variáveis de $ENV_FILE"
  set -a; . "$ENV_FILE"; set +a
fi

SPARK_HOME=${SPARK_HOME:-/opt/spark}
SPARK_USER=${SPARK_USER:-spark}
SPARK_MINIO_ENDPOINT=${SPARK_MINIO_ENDPOINT:-http://minio.gti.local:9000}
SPARK_MINIO_USER=${SPARK_MINIO_USER:-spark_user}
SPARK_MINIO_PASS=${SPARK_MINIO_PASS:-SparkPass123!}
HIVE_METASTORE_URI=${HIVE_METASTORE_URI:-thrift://db-hive.gti.local:9083}
ICEBERG_WAREHOUSE=${ICEBERG_WAREHOUSE:-s3a://datalake/warehouse}

echo "Configurando $SPARK_HOME/conf/spark-defaults.conf"
mkdir -p "$SPARK_HOME/conf"
cat > "$SPARK_HOME/conf/spark-defaults.conf" <<EOF
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions

spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=$HIVE_METASTORE_URI
spark.sql.catalog.iceberg.warehouse=$ICEBERG_WAREHOUSE

spark.hadoop.fs.s3a.endpoint=$SPARK_MINIO_ENDPOINT
spark.hadoop.fs.s3a.access.key=$SPARK_MINIO_USER
spark.hadoop.fs.s3a.secret.key=$SPARK_MINIO_PASS
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false

spark.hadoop.fs.s3a.committer.name=directory
spark.hadoop.fs.s3a.committer.magic.enabled=false
spark.sql.sources.commitProtocolClass=org.apache.spark.internal.io.cloud.PathOutputCommitProtocol
spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter
EOF

chown "$SPARK_USER:$SPARK_USER" "$SPARK_HOME/conf/spark-defaults.conf" 2>/dev/null || true

echo "Configurando spark-env.sh (HADOOP_CONF_DIR, HADOOP_HOME, JAVA_HOME, PATH)"
cat > "$SPARK_HOME/conf/spark-env.sh" <<EOF
#!/usr/bin/env bash
export SPARK_HOME=$SPARK_HOME
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/opt/hive/conf}
export HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}
export PATH=
EOF

chown "$SPARK_USER:$SPARK_USER" "$SPARK_HOME/conf/spark-env.sh" 2>/dev/null || true
chmod 755 "$SPARK_HOME/conf/spark-env.sh"

echo "Configurando permissões e usuário "$SPARK_USER"
if id -u "$SPARK_USER" >/dev/null 2>&1; then
  chown -R "$SPARK_USER:$SPARK_USER" "$SPARK_HOME"
fi

echo "Configuração do Spark concluída. Reinicie os serviços (master/worker) via systemd quando aplicável."

exit 0
