#!/usr/bin/env python3

from pyspark.sql import SparkSession

# Criar SparkSession usando configurações dos arquivos conf
spark = SparkSession.builder \
    .appName("TestSparkS3") \
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