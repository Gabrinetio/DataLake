from pyspark.sql import SparkSession

def main():
    print("Inicializando Sessão Spark (Teste Mínimo de JSON)...")
    spark = SparkSession.builder \
        .appName("S3JsonVerify") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "datalake") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    
    # Listar arquivos primeiro usando a API do Hadoop para confirmar os caminhos
    hadoop_conf = spark._jsc.hadoopConfiguration()
    uri = spark._jvm.java.net.URI("s3a://datalake/topics/datagen.customer.events/")
    fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(uri, hadoop_conf)
    
    print("Listando arquivos recursivamente para encontrar um único arquivo JSON...")
    json_path = None
    
    # Wrapper simples para listagem recursiva
    def list_recursive(path_str):
        p = spark._jvm.org.apache.hadoop.fs.Path(path_str)
        if not fs.exists(p):
            return None
        
        status_list = fs.listStatus(p)
        for s in status_list:
            if s.isDirectory():
                res = list_recursive(s.getPath().toString())
                if res: return res
            elif s.getPath().getName().endswith(".json"):
                return s.getPath().toString()
        return None

    json_path = list_recursive("s3a://datalake/topics/datagen.customer.events/")
    
    if not json_path:
        print("❌ Nenhum arquivo JSON encontrado em s3a://datalake/topics/datagen.customer.events/")
        return

    print(f"✅ Arquivo JSON encontrado: {json_path}")
    print("Lendo arquivo único para inferir esquema...")
    
    try:
        df = spark.read.json(json_path)
        print("✅ Esquema Inferido:")
        df.printSchema()
        df.show(1)
        
        # Agora tentar escrever na tabela Iceberg usando este esquema
        print("\nEscrevendo na tabela Iceberg...")
        spark.sql("CREATE CHECKPOINT IF NOT EXISTS iceberg_checkpoint")
        
        # Criar tabela manualmente para evitar ambiguidade 'createOrReplace' em algumas versões
        # ou apenas usar DataFrameWriterV2
        
        print("Criando banco de dados iceberg.default se não existir...")
        spark.sql("CREATE DATABASE IF NOT EXISTS iceberg.default")
        
        # Escrever
        df.writeTo("iceberg.default.customer_events").createOrReplace()
        print("✅ Sucesso! Tabela criada.")
        
    except Exception as e:
        print(f"❌ Erro: {e}")

if __name__ == "__main__":
    main()
