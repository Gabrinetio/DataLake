from pyspark.sql import SparkSession
from pyspark.sql.functions import col

def main():
    print("Inicializando Sessão Spark...")
    spark = SparkSession.builder \
        .appName("DataLakeVerify") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "datalake") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .getOrCreate()
    
    # Configurar logging para ser menos verboso
    spark.sparkContext.setLogLevel("WARN")

    print("Lendo dados do S3 (JSON Bruto) com busca recursiva...")
    # Simplificar caminho para a raiz do bucket + topics
    raw_path = "s3a://datalake/topics/datagen.customer.events/"
    
    try:
        # Usar recursiveFileLookup para evitar problemas complexos de globbing
        df = spark.read \
            .option("recursiveFileLookup", "true") \
            .option("pathGlobFilter", "*.json") \
            .json(raw_path)
            
        count = df.count()
        print(f"✅ Leitura de {count} registros do S3 realizada com sucesso!")
        
        print("\nEsquema:")
        df.printSchema()
        
        # Verificar escrita no Iceberg
        print("\nEscrevendo na tabela Iceberg (iceberg.default.customer_events)...")
        # Garantir que o banco de dados existe
        spark.sql("CREATE DATABASE IF NOT EXISTS iceberg.default")
        
        # Escrever no Iceberg - Modo Append, criando a tabela se necessário
        # Nós descartamos a struct 'payload' para colunas planas ou mantemos como está. Vamos manter como está por enquanto.
        df.writeTo("iceberg.default.customer_events") \
            .append()
            
        print("✅ Dados escritos com sucesso na tabela Iceberg!")
        
        # Verificar Leitura Iceberg
        print("\nLendo de volta do Iceberg...")
        iceberg_df = spark.table("iceberg.default.customer_events")
        print(f"Contagem da Tabela Iceberg: {iceberg_df.count()}")
        iceberg_df.show(5)
        
    except Exception as e:
        print(f"❌ Erro durante verificação: {e}")

if __name__ == "__main__":
    main()
