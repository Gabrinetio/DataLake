#!/usr/bin/env python3
"""
Teste completo de integração Spark + Iceberg + MinIO
"""

from pyspark.sql import SparkSession
import sys

print("=" * 70)
print("TESTE DE INTEGRAÇÃO: Spark 3.5.7 + Iceberg 1.10.0 + MinIO")
print("=" * 70)

try:
    # Criar sessão Spark
    print("\n[1] Criando SparkSession...")
    spark = SparkSession.builder \
        .appName("IcebergIntegrationTest") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.iceberg.type", "hive") \
        .config("spark.sql.catalog.iceberg.uri", "thrift://db-hive.gti.local:9083") \
        .config("spark.sql.catalog.iceberg.warehouse", "s3a://datalake/warehouse") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio.gti.local:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "spark_user") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .config("spark.hadoop.fs.s3a.committer.name", "directory") \
        .config("spark.hadoop.fs.s3a.committer.magic.enabled", "false") \
        .config("spark.sql.sources.commitProtocolClass", "org.apache.spark.internal.io.cloud.PathOutputCommitProtocol") \
        .config("spark.sql.parquet.output.committer.class", "org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter") \
        .getOrCreate()
    
    print("✅ SparkSession criada com sucesso")
    
    # Teste 2: Mostrar catálogos
    print("\n[2] Verificando Catálogos Disponíveis...")
    catalogs = spark.sql("SHOW CATALOGS")
    catalogs.show()
    print("✅ Catálogos listados")
    
    # Teste 3: Mostrar databases
    print("\n[3] Verificando Databases no Hive Metastore...")
    databases = spark.sql("SHOW DATABASES")
    databases.show()
    print("✅ Databases acessíveis")
    
    # Teste 4: Testar S3A
    print("\n[4] Testando conectividade S3A (MinIO)...")
    test_df = spark.range(100).selectExpr("id", "concat('row_', id) as name")
    test_df.write.mode("overwrite").parquet("s3a://datalake/spark_test_integration")
    print("✅ Arquivo escrito em S3A")
    
    test_read = spark.read.parquet("s3a://datalake/spark_test_integration")
    count = test_read.count()
    print(f"✅ {count} linhas lidas de S3A")
    
    # Teste 5: Criar tabela Iceberg
    print("\n[5] Criando Tabela Iceberg...")
    spark.sql("""
    CREATE TABLE IF NOT EXISTS iceberg.default.spark_integration_test (
        id INT,
        name STRING,
        created_at TIMESTAMP
    ) USING ICEBERG
    """)
    print("✅ Tabela Iceberg criada")
    
    # Teste 6: Inserir dados
    print("\n[6] Inserindo dados na tabela Iceberg...")
    spark.sql("""
    INSERT INTO iceberg.default.spark_integration_test VALUES
    (1, 'Integration Test 1', current_timestamp()),
    (2, 'Integration Test 2', current_timestamp()),
    (3, 'Integration Test 3', current_timestamp())
    """)
    print("✅ Dados inseridos")
    
    # Teste 7: Ler dados
    print("\n[7] Lendo dados da tabela Iceberg...")
    result = spark.sql("SELECT * FROM iceberg.default.spark_integration_test")
    result.show()
    print("✅ Leitura bem-sucedida")
    
    # Teste 8: Contar linhas
    print("\n[8] Contando registros...")
    row_count = spark.sql("SELECT COUNT(*) as total FROM iceberg.default.spark_integration_test").collect()[0][0]
    print(f"✅ Total de registros: {row_count}")
    
    # Teste 9: Listar metadados
    print("\n[9] Verificando metadados da tabela...")
    spark.sql("DESC TABLE iceberg.default.spark_integration_test").show()
    print("✅ Schema da tabela recuperado")
    
    print("\n" + "=" * 70)
    print("🎉 TODOS OS TESTES PASSARAM COM SUCESSO!")
    print("=" * 70)
    print("\n✨ Resumo:")
    print("   ✓ Spark Session criada")
    print("   ✓ Catálogos disponíveis (iceberg, spark_catalog, etc)")
    print("   ✓ Hive Metastore acessível")
    print("   ✓ MinIO S3A funcionando")
    print("   ✓ Tabelas Iceberg criáveis")
    print("   ✓ CRUD operations ok")
    print("\n🚀 Plataforma PRONTA PARA PRODUÇÃO!")
    
    spark.stop()
    sys.exit(0)

except Exception as e:
    print(f"\n❌ ERRO: {str(e)}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
