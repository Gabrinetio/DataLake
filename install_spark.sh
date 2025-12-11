#!/bin/bash
# Script de instalação do Apache Spark 3.5.7 no CT Spark
# Executar como root ou com sudo

set -e  # Exit on error

echo "=========================================="
echo "Instalação do Apache Spark 3.5.7"
echo "=========================================="

# 1. Download e Extração
echo "[1/6] Baixando Spark 3.5.7..."
cd /opt
if [ ! -d "spark" ]; then
    wget -q https://downloads.apache.org/spark/spark-3.5.7/spark-3.5.7-bin-hadoop3.tgz
    tar -xzf spark-3.5.7-bin-hadoop3.tgz
    mv spark-3.5.7-bin-hadoop3 spark
    rm spark-3.5.7-bin-hadoop3.tgz
    echo "✅ Spark extraído com sucesso"
else
    echo "⚠️  Spark já existe em /opt/spark"
fi

# 2. Ajustar permissões
echo "[2/6] Ajustando permissões..."
chown -R datalake:datalake /opt/spark
chmod -R 755 /opt/spark
echo "✅ Permissões ajustadas"

# 3. Configurar variáveis de ambiente
echo "[3/6] Configurando variáveis de ambiente..."
if ! grep -q "SPARK_HOME=/opt/spark" /etc/profile; then
    cat >> /etc/profile << 'EOF'

# Apache Spark
export SPARK_HOME=/opt/spark
export PATH=$PATH:$SPARK_HOME/bin
EOF
    echo "✅ Variáveis de ambiente adicionadas"
else
    echo "⚠️  Variáveis já existem em /etc/profile"
fi

# 4. Criar diretório para JARs e baixar dependências
echo "[4/6] Instalando JARs (Iceberg, Hadoop-AWS, AWS SDK)..."
mkdir -p /opt/spark/jars

cd /opt/spark/jars
echo "  - Baixando Iceberg 1.10.0..."
wget -q -O iceberg-spark-runtime-3.5_2.12-1.10.0.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.10.0/iceberg-spark-runtime-3.5_2.12-1.10.0.jar

echo "  - Baixando Hadoop-AWS 3.3.4..."
wget -q -O hadoop-aws-3.3.4.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar

echo "  - Baixando AWS SDK Bundle 1.12.262..."
wget -q -O aws-java-sdk-bundle-1.12.262.jar \
    https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar

echo "  - Baixando Spark SQL Kafka 3.5.7..."
wget -q -O spark-sql-kafka-0-10_2.12-3.5.7.jar \
    https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.5.7/spark-sql-kafka-0-10_2.12-3.5.7.jar

echo "✅ JARs instalados com sucesso"

# 5. Criar arquivo spark-defaults.conf
echo "[5/6] Criando spark-defaults.conf..."
cat > /opt/spark/conf/spark-defaults.conf << 'EOF'
# Apache Spark Defaults Configuration
# DataLake - Iceberg + MinIO + Hive Metastore

spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions

spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=thrift://db-hive.gti.local:9083
spark.sql.catalog.iceberg.warehouse=s3a://datalake/warehouse

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

# Performance e Recursos
spark.driver.memory=2g
spark.executor.memory=2g
spark.executor.cores=2
spark.default.parallelism=4
EOF

chown datalake:datalake /opt/spark/conf/spark-defaults.conf
echo "✅ spark-defaults.conf criado"

# 6. Teste de versão
echo "[6/6] Testando instalação..."
source /etc/profile
$SPARK_HOME/bin/spark-submit --version || echo "⚠️  spark-submit ainda não está no PATH (será necessário fazer source /etc/profile ou reiniciar shell)"

echo ""
echo "=========================================="
echo "✅ INSTALAÇÃO DO SPARK CONCLUÍDA!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Source /etc/profile: source /etc/profile"
echo "2. Testar Spark: spark-shell"
echo "3. Iniciar Spark Master: /opt/spark/sbin/start-master.sh"
echo ""
