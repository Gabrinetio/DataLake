from pyspark.sql import SparkSession

def main():
    print("Initializing Spark Session (Minimal S3 Test)...")
    spark = SparkSession.builder \
        .appName("S3ConnectivityTest") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "datalake") \
        .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .config("spark.hadoop.fs.s3a.connection.establish.timeout", "5000") \
        .config("spark.hadoop.fs.s3a.connection.timeout", "10000") \
        .config("spark.hadoop.fs.s3a.attempts.maximum", "1") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("INFO")
    
    print("Testing connection to S3 Root (s3a://datalake/)...")
    try:
        # Pega o contexto Hadoop para usar o FileSystem diretamente
        # Isso evita overhead de inferência de schema e testa conectividade pura
        hadoop_conf = spark._jsc.hadoopConfiguration()
        uri = spark._jvm.java.net.URI("s3a://datalake/")
        fs = spark._jvm.org.apache.hadoop.fs.FileSystem.get(uri, hadoop_conf)
        
        status = fs.listStatus(spark._jvm.org.apache.hadoop.fs.Path("s3a://datalake/"))
        print(f"✅ Connection Successful! Found {len(status)} items in root:")
        for file_status in status:
            print(f" - {file_status.getPath().getName()}")
            
    except Exception as e:
        print(f"❌ Connection Failed: {e}")
        # Print full stack trace if possible
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
