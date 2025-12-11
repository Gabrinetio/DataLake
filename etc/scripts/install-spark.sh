#!/usr/bin/env bash
set -euo pipefail

# install-spark.sh
# Instala o Apache Spark (standalone) + jars Iceberg e Hadoop-AWS para integração com MinIO
# Uso: install-spark.sh [SPARK_VERSION]

SPARK_VERSION=${1:-${SPARK_VERSION:-3.5.7}}
SPARK_DOWNLOAD_BASE=${SPARK_DOWNLOAD_BASE:-https://downloads.apache.org/spark}
SPARK_ARCHIVE="spark-${SPARK_VERSION}-bin-hadoop3.tgz"
SPARK_URL="$SPARK_DOWNLOAD_BASE/spark-${SPARK_VERSION}/${SPARK_ARCHIVE}"
SPARK_HOME=${SPARK_HOME:-/opt/spark}
SPARK_USER=${SPARK_USER:-spark}
SPARK_GROUP=${SPARK_GROUP:-spark}
JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}

echo "Instalando Apache Spark $SPARK_VERSION no $SPARK_HOME"

apt-get update && apt-get install -y default-jdk wget curl tar || true

# Criar usuário spark se não existir
if ! id -u "$SPARK_USER" >/dev/null 2>&1; then
  adduser --system --home "$SPARK_HOME" --group "$SPARK_USER" || true
fi

mkdir -p /tmp/spark-install
cd /tmp/spark-install

echo "Baixando Spark: $SPARK_URL"
if [ ! -f "$SPARK_ARCHIVE" ]; then
  wget -q "$SPARK_URL" -O "$SPARK_ARCHIVE"
fi

tar -xzf "$SPARK_ARCHIVE"
SPARK_EXTRACTED_DIR=$(tar -tf "$SPARK_ARCHIVE" | head -n1 | cut -f1 -d"/")

rm -rf "$SPARK_HOME"
mv "$SPARK_EXTRACTED_DIR" "$SPARK_HOME"
chown -R "$SPARK_USER:$SPARK_GROUP" "$SPARK_HOME"

mkdir -p "$SPARK_HOME/jars/iceberg"

echo "Baixando jars adicionais (Iceberg, Hadoop AWS, AWS SDK)"
JARS_DIR=/tmp/spark-jars
mkdir -p "$JARS_DIR"
cd "$JARS_DIR"

# Iceberg (runtime para Spark 3.5 + Scala 2.12)
ICEBERG_VERSION=${ICEBERG_VERSION:-1.10.0}
ICEBERG_JAR="iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar"
if [ ! -f "$ICEBERG_JAR" ]; then
  wget -q "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VERSION}/${ICEBERG_JAR}"
fi

# Hadoop AWS and AWS SDK (compatível com MinIO via S3A)
HADOOP_AWS_VER=${HADOOP_AWS_VER:-3.3.4}
HADOOP_AWS_JAR="hadoop-aws-${HADOOP_AWS_VER}.jar"
if [ ! -f "$HADOOP_AWS_JAR" ]; then
  wget -q "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VER}/${HADOOP_AWS_JAR}"
fi

AWS_SDK_VER=${AWS_SDK_VER:-1.12.262}
AWS_SDK_JAR="aws-java-sdk-bundle-${AWS_SDK_VER}.jar"
if [ ! -f "$AWS_SDK_JAR" ]; then
  wget -q "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VER}/${AWS_SDK_JAR}"
fi

echo "Copiando jars para $SPARK_HOME/jars/"
cp -v "$ICEBERG_JAR" "$HADOOP_AWS_JAR" "$AWS_SDK_JAR" "$SPARK_HOME/jars/"
chown "$SPARK_USER:$SPARK_GROUP" "$SPARK_HOME/jars/"* || true

echo "Criando configuração inicial do Spark (spark-env.sh e spark-defaults.conf)"
mkdir -p "$SPARK_HOME/conf"
cat > "$SPARK_HOME/conf/spark-env.sh" <<EOF
#!/usr/bin/env bash
export SPARK_HOME=$SPARK_HOME
export HADOOP_HOME=${HADOOP_HOME:-/opt/hadoop}
export JAVA_HOME=$JAVA_HOME
export PATH=
export SPARK_DIST_CLASSPATH=
export SPARK_MASTER_HOST=${SPARK_MASTER_HOST:-0.0.0.0}
EOF
chown "$SPARK_USER:$SPARK_GROUP" "$SPARK_HOME/conf/spark-env.sh"
chmod 755 "$SPARK_HOME/conf/spark-env.sh"

cat > "$SPARK_HOME/conf/spark-defaults.conf" <<'EOF'
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions

spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=thrift://db-hive.gti.local:9083
spark.sql.catalog.iceberg.warehouse=s3a://datalake/warehouse

spark.hadoop.fs.s3a.endpoint=http://minio.gti.local:9000
spark.hadoop.fs.s3a.access.key=spark_user
spark.hadoop.fs.s3a.secret.key=SparkPass123!
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false

spark.hadoop.fs.s3a.committer.name=directory
spark.hadoop.fs.s3a.committer.magic.enabled=false
spark.sql.sources.commitProtocolClass=org.apache.spark.internal.io.cloud.PathOutputCommitProtocol
spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter
EOF

chown "$SPARK_USER:$SPARK_GROUP" "$SPARK_HOME/conf/spark-defaults.conf"

echo "Instalação do Spark concluída em $SPARK_HOME. Ajuste o arquivo spark-defaults.conf conforme necessário (ex: credenciais)."

echo "Para startar os serviços (ex.: master): sudo -u $SPARK_USER $SPARK_HOME/sbin/start-master.sh" 

rm -rf /tmp/spark-install
rm -rf "$JARS_DIR"

exit 0
