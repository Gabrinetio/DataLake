from pyspark.sql import SparkSession

def main():
    print("Inicializando Sessão Spark para DDL Iceberg...")
    spark = SparkSession.builder \
        .appName("IcebergDDL") \
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
        .config("spark.driver.memory", "1g") \
        .config("spark.executor.memory", "1g") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")

    print("Criando banco de dados iceberg.default...")
    spark.sql("CREATE DATABASE IF NOT EXISTS iceberg.default")
    
    print("Criando Tabela iceberg.default.customer_events_raw...")
    # Usando um esquema genérico refletindo o JSON que vimos anteriormente
    # event_id, event_ts, event_type, payload (string/struct), etc.
    # Para a camada Raw, manter o payload como String é frequentemente mais seguro, ou podemos confiar na evolução do esquema.
    
    ddl = """
    CREATE TABLE IF NOT EXISTS iceberg.default.customer_events_raw (
        event_id STRING,
        event_ts STRING,
        event_type STRING,
        payload STRING,
        producer STRING,
        schema_version STRING,
        tenant STRING,
        trace STRING
    )
    USING iceberg
    PARTITIONED BY (truncate(4, event_ts))
    """
    
    try:
        spark.sql(ddl)
        print("✅ Tabela criada com sucesso.")
    except Exception as e:
        print(f"❌ Erro ao criar tabela: {e}")

if __name__ == "__main__":
    main()
