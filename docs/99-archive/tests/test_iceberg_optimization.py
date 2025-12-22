from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year, month, current_timestamp
from src.config import get_spark_s3_config

# Configurar SparkSession com Iceberg
spark_config = get_spark_s3_config()
spark = SparkSession.builder \
    .appName("TestOptimization") \
    .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
    .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .getOrCreate()

print("=" * 60)
print("DEMONSTRAÇÃO DE OTIMIZAÇÃO E MONITORAMENTO DE TABELAS ICEBERG")
print("=" * 60)

# 1. Visualizar metadados da tabela
print("\n1. METADADOS DA TABELA:")
print("-" * 60)
spark.sql("DESCRIBE EXTENDED hadoop_prod.default.vendas_partitioned").show(20, truncate=False)

# 2. Visualizar snapshots
print("\n2. SNAPSHOTS DA TABELA:")
print("-" * 60)
spark.sql("SELECT snapshot_id, timestamp_ms, operation FROM hadoop_prod.default.vendas_partitioned.snapshots").show(truncate=False)

# 3. Visualizar arquivos de dados
print("\n3. ARQUIVOS DE DADOS:")
print("-" * 60)
spark.sql("SELECT file_path, file_size_in_bytes, record_count FROM hadoop_prod.default.vendas_partitioned.files WHERE content = 0").show(truncate=False)

# 4. Visualizar arquivos de manifesto
print("\n4. MANIFESTOS:")
print("-" * 60)
spark.sql("SELECT path, length FROM hadoop_prod.default.vendas_partitioned.manifests").show(truncate=False)

# 5. Estatísticas da tabela
print("\n5. ESTATÍSTICAS GERAIS:")
print("-" * 60)
df_stats = spark.sql("SELECT COUNT(*) as total_rows FROM hadoop_prod.default.vendas_partitioned")
df_stats.show()

# 6. Análise de particionamento
print("\n6. DISTRIBUIÇÃO POR PARTIÇÃO:")
print("-" * 60)
spark.sql("""
SELECT ano, mes, COUNT(*) as quantidade
FROM hadoop_prod.default.vendas_partitioned
GROUP BY ano, mes
ORDER BY ano, mes
""").show()

# 7. Vacuum (limpeza de arquivos órfãos)
print("\n7. EXECUTANDO VACUUM (limpeza):")
print("-" * 60)
spark.sql("CALL hadoop_prod.system.remove_orphan_files(table => 'hadoop_prod.default.vendas_partitioned')")
print("Vacuum concluído!")

# 8. Rewrite dos arquivos de manifesto (compactação)
print("\n8. REWRITE MANIFESTS (otimização de leitura):")
print("-" * 60)
spark.sql("CALL hadoop_prod.system.rewrite_manifests(table => 'hadoop_prod.default.vendas_partitioned')")
print("Rewrite de manifests concluído!")

print("\n" + "=" * 60)
print("OTIMIZAÇÃO E MONITORAMENTO CONCLUÍDO COM SUCESSO!")
print("=" * 60)

spark.stop()
