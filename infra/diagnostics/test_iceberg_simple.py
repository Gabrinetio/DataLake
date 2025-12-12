#!/usr/bin/env python3
"""Teste simplificado de Spark + Iceberg"""

from pyspark.sql import SparkSession
import sys

print("Teste Spark + Iceberg (versao simplificada)")
print("="*60)

try:
    spark = SparkSession.builder \
        .appName("IcebergTest") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.iceberg.type", "hive") \
        .config("spark.sql.catalog.iceberg.uri", "thrift://db-hive.gti.local:9083") \
        .config("spark.sql.catalog.iceberg.warehouse", "s3a://datalake/warehouse") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio.gti.local:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "spark_user") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .getOrCreate()
    
    print("\n[1] OK - Spark Session criada")
    
    # Teste: Catalogs
    print("\n[2] Testando Catalogs...")
    result = spark.sql("SHOW CATALOGS").collect()
    for row in result:
        print(f"  - {row[0]}")
    print("  OK - Catalogs disponiveis")
    
    # Teste: Databases
    print("\n[3] Testando Hive Metastore...")
    dbs = spark.sql("SHOW DATABASES").collect()
    for db in dbs:
        print(f"  - {db[0]}")
    print("  OK - Hive Metastore acessivel")
    
    # Teste: Criar tabela Iceberg simples
    print("\n[4] Testando Tabelas Iceberg...")
    spark.sql("""
    CREATE TABLE IF NOT EXISTS iceberg.default.quick_test (
        id INT,
        value STRING
    ) USING ICEBERG
    """)
    print("  OK - Tabela Iceberg criada")
    
    # Teste: Inserir
    print("\n[5] Inserindo dados...")
    spark.sql("INSERT INTO iceberg.default.quick_test VALUES (1, 'test')")
    print("  OK - Dados inseridos")
    
    # Teste: Ler
    print("\n[6] Lendo dados...")
    data = spark.sql("SELECT * FROM iceberg.default.quick_test").collect()
    for row in data:
        print(f"  ID: {row[0]}, Value: {row[1]}")
    print("  OK - Leitura bem-sucedida")
    
    print("\n" + "="*60)
    print("TODOS OS TESTES PASSARAM!")
    print("Plataforma Spark + Iceberg + Hive + MinIO FUNCIONAL")
    print("="*60)
    
    spark.stop()

except Exception as e:
    print(f"\nERRO: {str(e)}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
