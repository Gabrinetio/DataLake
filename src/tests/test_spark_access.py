#!/usr/bin/env python3

from pyspark.sql import SparkSession
from src.config import get_spark_s3_config

# Configurações S3 carregadas de .env via src.config
spark_config = get_spark_s3_config()

# Adicionar configurações específicas do teste
spark_config.update({
    "spark.sql.catalog.spark_catalog.type": "hive",
    "spark.sql.catalog.spark_catalog.uri": "thrift://db-hive.gti.local:9083",
    "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
})

# Criar SparkSession com configurações
spark = SparkSession.builder \
    .appName("TestSparkS3") \
    .configs(spark_config) \
    .enableHiveSupport() \
    .getOrCreate()

try:
    # Tentar listar buckets (isso testa as credenciais S3)
    fs = spark.sparkContext._jvm.org.apache.hadoop.fs.FileSystem.get(spark.sparkContext._jsc.hadoopConfiguration())
    s3a = spark.sparkContext._jvm.org.apache.hadoop.fs.Path("s3a://")
    buckets = fs.listStatus(s3a)
    print("Buckets encontrados:")
    for bucket in buckets:
        print(f"- {bucket.getPath().getName()}")
    print("Teste de acesso S3: SUCESSO")
except Exception as e:
    print(f"Erro no teste S3: {e}")
    print("Verifique credenciais e conectividade com MinIO.")

# Testar catálogo Iceberg/Hive
try:
    spark.sql("SHOW DATABASES").show()
    print("Teste de acesso Hive/Iceberg: SUCESSO")
except Exception as e:
    print(f"Erro no teste Hive: {e}")
    print("Verifique se Hive Metastore está rodando.")

spark.stop()