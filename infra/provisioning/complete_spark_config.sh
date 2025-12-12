#!/bin/bash
# Script para complementar e corrigir configuração do Spark

SPARK_CONF_DIR="/opt/spark/spark-3.5.7-bin-hadoop3/conf"
SPARK_HOME="/opt/spark/spark-3.5.7-bin-hadoop3"

echo "=========================================="
echo "Completando Configuração do Spark 3.5.7"
echo "=========================================="

# 1. Verificar JARs
echo "[1/4] Verificando JARs..."
JARS_DIR="/opt/spark/jars"
cd "$JARS_DIR"

if [ ! -f "iceberg-spark-runtime-3.5_2.12-1.10.0.jar" ]; then
    echo "  - Baixando Iceberg 1.10.0..."
    wget -q https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.10.0/iceberg-spark-runtime-3.5_2.12-1.10.0.jar
fi

if [ ! -f "hadoop-aws-3.3.4.jar" ]; then
    echo "  - Baixando Hadoop-AWS 3.3.4..."
    wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar
fi

if [ ! -f "aws-java-sdk-bundle-1.12.262.jar" ]; then
    echo "  - Baixando AWS SDK Bundle..."
    wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar
fi

if [ ! -f "spark-sql-kafka-0-10_2.12-3.5.7.jar" ]; then
    echo "  - Baixando Spark SQL Kafka..."
    wget -q https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.7/spark-sql-kafka-0-10_2.12-3.5.7.jar
fi

ls -lh "$JARS_DIR"/*.jar 2>/dev/null | wc -l | xargs -I {} echo "✅ {} JARs presentes"

# 2. Criar backup do spark-defaults.conf
echo "[2/4] Criando backup de spark-defaults.conf..."
BACKUP_FILE="$SPARK_CONF_DIR/spark-defaults.conf.backup.$(date +%Y%m%d_%H%M%S)"
cp "$SPARK_CONF_DIR/spark-defaults.conf" "$BACKUP_FILE"
echo "✅ Backup criado: $BACKUP_FILE"

# 3. Atualizar spark-defaults.conf com configurações completas
echo "[3/4] Atualizando spark-defaults.conf..."
cat > "$SPARK_CONF_DIR/spark-defaults.conf" << 'EOF'
# Apache Spark Defaults Configuration
# DataLake - Iceberg + MinIO + Hive Metastore + Kafka
# Última atualização: 10 de dezembro de 2025

# ============ ICEBERG CONFIGURATION ============
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions

spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=thrift://db-hive.gti.local:9083
spark.sql.catalog.iceberg.warehouse=s3a://datalake/warehouse

# ============ S3A/MINIO CONFIGURATION ============
spark.hadoop.fs.s3a.endpoint=http://minio.gti.local:9000
spark.hadoop.fs.s3a.access.key=spark_user
spark.hadoop.fs.s3a.secret.key=SENHA_SPARK_MINIO
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false

spark.hadoop.fs.s3a.committer.name=directory
spark.hadoop.fs.s3a.committer.magic.enabled=false
spark.sql.sources.commitProtocolClass=org.apache.spark.internal.io.cloud.PathOutputCommitProtocol
spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter

# ============ MEMORY & PERFORMANCE ============
spark.driver.memory=4g
spark.executor.memory=4g
spark.executor.cores=2
spark.default.parallelism=8
spark.sql.shuffle.partitions=8
spark.iceberg.shuffle.num-partitions=8

# ============ ADAPTIVE QUERY EXECUTION ============
spark.sql.adaptive.enabled=true
spark.sql.adaptive.skewJoin.enabled=true
spark.sql.adaptive.coalescePartitions.enabled=true
spark.sql.adaptive.coalescePartitions.minPartitionNum=1
spark.sql.adaptive.coalescePartitions.initialPartitionNum=8

# ============ STATISTICS & CBO ============
spark.sql.statistics.histogram.enabled=true
spark.sql.cbo.enabled=true
spark.sql.cbo.joinReorder.enabled=true

# ============ ICEBERG OPTIMIZATIONS ============
spark.iceberg.split.planning.open-file-cost=4194304
spark.iceberg.write.parquet.compression-codec=snappy
spark.iceberg.write.parquet.row-group-size-bytes=134217728
spark.iceberg.write.target-file-size-bytes=536870912

# ============ COMPRESSION & I/O ============
spark.sql.inMemoryColumnarStorage.compressed=true
spark.sql.inMemoryColumnarStorage.batchSize=10000
spark.shuffle.compress=true
spark.shuffle.spill.compress=true
spark.broadcast.compress=true
spark.rdd.compress=true

# ============ LOGGING ============
spark.eventLog.dir=/opt/spark/logs/events
EOF

chown datalake:datalake "$SPARK_CONF_DIR/spark-defaults.conf"
echo "✅ spark-defaults.conf atualizado com sucesso"

# 4. Configurar PATH e variáveis de ambiente
echo "[4/4] Configurando variáveis de ambiente..."
if ! grep -q "SPARK_HOME=/opt/spark/spark-3.5.7-bin-hadoop3" /etc/profile; then
    cat >> /etc/profile << 'EOF'

# Apache Spark Configuration
export SPARK_HOME=/opt/spark/spark-3.5.7-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin
EOF
fi

echo "✅ Variáveis de ambiente configuradas"

# 5. Testar instalação
echo ""
echo "=========================================="
echo "Testando Instalação"
echo "=========================================="

# Source do perfil
source /etc/profile

# Verificar spark-submit
if [ -x "$SPARK_HOME/bin/spark-submit" ]; then
    echo "✅ spark-submit encontrado e executável"
    echo ""
    echo "Versão do Spark:"
    $SPARK_HOME/bin/spark-submit --version | head -3
else
    echo "❌ spark-submit não encontrado"
fi

# Verificar JARs
echo ""
echo "JARs instalados:"
ls -lh "$JARS_DIR"/*.jar 2>/dev/null | awk '{print "  -", $9, "(" $5 ")"}'

echo ""
echo "=========================================="
echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Aplicar variáveis: source /etc/profile"
echo "2. Testar shell Spark: spark-shell"
echo "3. Iniciar Spark Master: /opt/spark/sbin/start-master.sh"
echo "4. Iniciar Spark Workers: /opt/spark/sbin/start-workers.sh"
echo ""
