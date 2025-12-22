#!/usr/bin/env python3

"""
🚀 Teste MinIO S3 Authentication Fix
Script: test_minio_s3_fix.py
Data: 9 de dezembro de 2025

Testa se as credenciais MinIO S3 foram corrigidas
"""

from pyspark.sql import SparkSession

def test_s3_connectivity():
    """Testa conectividade básica com S3/MinIO"""
    print("🔍 TESTANDO CONECTIVIDADE MINIO S3")
    print("=" * 50)

    try:
        # Criar sessão Spark com configurações S3
        spark = SparkSession.builder \
            .appName("MinIO_S3_Test") \
            .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
            .config("spark.hadoop.fs.s3a.endpoint", "http://minio.gti.local:9000") \
            .config("spark.hadoop.fs.s3a.access.key", "datalake") \
            .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
            .config("spark.hadoop.fs.s3a.path.style.access", "true") \
            .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
            .getOrCreate()

        print("✅ Spark session criada com configurações S3")

        # Teste 1: Listar arquivos no bucket
        print("\n📋 Teste 1: Listando arquivos no bucket s3a://datalake/warehouse")
        try:
            files = spark.sparkContext.wholeTextFiles("s3a://datalake/warehouse/*")
            file_list = files.collect()
            print(f"   ✅ {len(file_list)} arquivos encontrados")
            if file_list:
                for file_path, _ in file_list[:3]:  # Mostra apenas os primeiros 3
                    print(f"      - {file_path}")
        except Exception as e:
            print(f"   ⚠️  Nenhum arquivo encontrado ou erro: {str(e)}")

        # Teste 2: Criar um arquivo de teste
        print("\n📝 Teste 2: Criando arquivo de teste")
        test_data = [("test", 1), ("data", 2), ("minio", 3)]
        test_df = spark.createDataFrame(test_data, ["name", "value"])

        # Salvar como Parquet no S3
        test_df.write.mode("overwrite").parquet("s3a://datalake/warehouse/test_minio_connectivity")
        print("   ✅ Arquivo de teste salvo em s3a://datalake/warehouse/test_minio_connectivity")

        # Teste 3: Ler o arquivo de volta
        print("\n📖 Teste 3: Lendo arquivo de teste")
        read_df = spark.read.parquet("s3a://datalake/warehouse/test_minio_connectivity")
        count = read_df.count()
        print(f"   ✅ {count} registros lidos com sucesso")

        # Mostrar conteúdo
        read_df.show()

        spark.stop()

        print("\n" + "=" * 50)
        print("🎉 SUCESSO! MINIO S3 AUTHENTICATION CORRIGIDA!")
        print("✅ Credenciais funcionando")
        print("✅ Leitura e escrita no S3/MinIO")
        print("✅ Spark integrado com MinIO")
        print("=" * 50)

        return True

    except Exception as e:
        print(f"❌ ERRO: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_s3_connectivity()
    exit(0 if success else 1)