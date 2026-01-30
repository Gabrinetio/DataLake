from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, to_timestamp
from pyspark.sql.types import StructType, StructField, StringType, TimestampType, MapType

def main():
    print("Inicializando Sessão Spark para Ingestão Iceberg...")
    spark = SparkSession.builder \
        .appName("IcebergIngestion") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "datalake") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.iceberg.type", "hive") \
        .config("spark.sql.catalog.iceberg.uri", "thrift://hive-metastore:9083") \
        .config("spark.sql.catalog.iceberg.warehouse", "s3a://datalake/warehouse") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    
    # 1. Ler JSON Bruto do S3
    print("Lendo Dados Brutos do S3...")
    raw_path = "s3a://datalake/topics/datagen.customer.events/"
    
    # Forçar esquema se necessário, mas inferência geralmente funciona para JSON simples
    # Usando busca recursiva para encontrar todos os arquivos de partição
    df_raw = spark.read \
        .option("recursiveFileLookup", "true") \
        .option("pathGlobFilter", "*.json") \
        .json(raw_path)
    
    print(f"Lidos {df_raw.count()} registros brutos.")
    
    # 2. Transformar / Flatten se necessário
    # Esquema Datagen: event_id, event_type, event_ts, payload (struct), etc.
    # Escreveremos 'como está' para uma tabela raw no Iceberg primeiro
    
    # 3. Criar/Anexar à Tabela Iceberg
    table_name = "iceberg.default.customer_events_raw"
    print(f"Escrevendo na Tabela Iceberg: {table_name}")
    
    spark.sql("CREATE DATABASE IF NOT EXISTS iceberg.default")
    
    # Usando DataFrameWriterV2 para Iceberg
    # Se a tabela existir, anexar. Se não, criar.
    try:
        df_raw.writeTo(table_name) \
            .append()
        print("✅ Dados anexados com sucesso à tabela Iceberg.")
    except Exception as e:
        # Fallback para criação de tabela se não existir (append pode falhar se tabela faltar dependendo da versão)
        print("A tabela pode não existir, tentando createOrReplace...")
        df_raw.writeTo(table_name) \
            .createOrReplace()
        print("✅ Tabela criada e dados escritos.")

    # 4. Verificar
    print("\nVerificando Dados no Iceberg:")
    spark.read.table(table_name).show(5, truncate=False)
    
    print("\nContagem de Linhas no Iceberg:")
    print(spark.read.table(table_name).count())

if __name__ == "__main__":
    main()
