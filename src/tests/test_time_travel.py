#!/usr/bin/env python3

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, concat, lit, when
from src.config import get_spark_s3_config
import sys

class TimeTravel:
    """Valida capacidades de Time Travel do Iceberg"""
    
    def __init__(self):
        # Configurações S3 carregadas de .env
        spark_config = get_spark_s3_config()
        
        # Adicionar configurações específicas para Iceberg
        spark_config.update({
            "spark.sql.catalog.hadoop_prod": "org.apache.iceberg.spark.SparkCatalog",
            "spark.sql.catalog.hadoop_prod.type": "hadoop",
            "spark.hadoop.fs.s3a.connection.ssl.enabled": "false",
            "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
        })
        
        self.spark = SparkSession.builder \
            .appName("IcebergTimeTravel") \
            .configs(spark_config) \
            .getOrCreate()
    
    def setup_table(self):
        """Cria tabela de teste"""
        
        print("\n" + "="*60)
        print("CONFIGURAÇÃO: Tabela de Time Travel")
        print("="*60)
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.time_travel_test")
        except:
            pass
        
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.time_travel_test (
            id BIGINT,
            value STRING,
            version INT,
            year INT,
            month INT
        )
        USING iceberg
        PARTITIONED BY (year, month)
        """)
        
        print("✓ Tabela criada")
    
    def insert_batch1(self):
        """Primeira batch de inserts - V1"""
        
        print("\n" + "="*60)
        print("LOTE 1: Inserir 10 registros (Versão 1)")
        print("="*60)
        
        df = self.spark.range(10) \
            .select(
                (col("id") + 1).alias("id"),
                expr("concat('value_v1_', id)").alias("value"),
                lit(1).alias("version"),
                lit(2025).alias("year"),
                lit(12).alias("month")
            )
        
        df.writeTo("hadoop_prod.default.time_travel_test").append()
        
        # Obter snapshot ID
        result = self.spark.sql("""
        SELECT snapshot_id, committed_at 
        FROM hadoop_prod.default.time_travel_test.snapshots
        ORDER BY committed_at DESC LIMIT 1
        """)
        
        snapshot = result.collect()[0]
        snapshot_id = snapshot["snapshot_id"]
        
        print(f"✓ Snapshot ID V1: {snapshot_id}")
        
        count = self.spark.sql("SELECT COUNT(*) as cnt FROM hadoop_prod.default.time_travel_test").collect()[0]["cnt"]
        print(f"✓ Total registros após Lote 1: {count}")
        
        return snapshot_id
    
    def insert_batch2(self):
        """Segunda batch - V2"""
        
        print("\n" + "="*60)
        print("LOTE 2: Inserir mais 10 registros (Versão 2)")
        print("="*60)
        
        df = self.spark.range(10, 20) \
            .select(
                (col("id") + 1).alias("id"),
                expr("concat('value_v2_', id)").alias("value"),
                lit(2).alias("version"),
                lit(2025).alias("year"),
                lit(12).alias("month")
            )
        
        df.writeTo("hadoop_prod.default.time_travel_test").append()
        
        result = self.spark.sql("""
        SELECT snapshot_id, committed_at 
        FROM hadoop_prod.default.time_travel_test.snapshots
        ORDER BY committed_at DESC LIMIT 1
        """)
        
        snapshot = result.collect()[0]
        snapshot_id = snapshot["snapshot_id"]
        
        print(f"✓ Snapshot ID V2: {snapshot_id}")
        
        count = self.spark.sql("SELECT COUNT(*) as cnt FROM hadoop_prod.default.time_travel_test").collect()[0]["cnt"]
        print(f"✓ Total registros após Lote 2: {count}")
        
        return snapshot_id
    
    def time_travel_test(self, snapshot_v1, snapshot_v2):
        """Valida Time Travel"""
        
        print("\n" + "="*60)
        print("TIME TRAVEL: Comparação de Snapshots")
        print("="*60)
        
        # Current
        print("\n📊 ESTADO ATUAL:")
        current = self.spark.sql("""
        SELECT version, COUNT(*) as count 
        FROM hadoop_prod.default.time_travel_test
        GROUP BY version
        ORDER BY version
        """)
        current.show()
        
        # Version 1
        print("\n📊 VERSÃO 1 (Snapshot ID: " + str(snapshot_v1) + "):")
        v1 = self.spark.sql(f"""
        SELECT version, COUNT(*) as count 
        FROM hadoop_prod.default.time_travel_test VERSION AS OF {snapshot_v1}
        GROUP BY version
        ORDER BY version
        """)
        v1.show()
        
        # Version 2
        print("\n📊 VERSÃO 2 (Snapshot ID: " + str(snapshot_v2) + "):")
        v2 = self.spark.sql(f"""
        SELECT version, COUNT(*) as count 
        FROM hadoop_prod.default.time_travel_test VERSION AS OF {snapshot_v2}
        GROUP BY version
        ORDER BY version
        """)
        v2.show()
        
        # Detailed comparison
        print("\n📊 DADOS DE AMOSTRA - ATUAL:")
        self.spark.sql("SELECT * FROM hadoop_prod.default.time_travel_test LIMIT 5").show()
        
        print("\n📊 DADOS DE AMOSTRA - V1:")
        self.spark.sql(f"""
        SELECT * FROM hadoop_prod.default.time_travel_test VERSION AS OF {snapshot_v1} LIMIT 5
        """).show()
    
    def run(self):
        """Executa teste completo"""
        
        print("\n" + "="*80)
        print("ITERAÇÃO 2 - VALIDAÇÃO DE TIME TRAVEL")
        print("="*80)
        
        self.setup_table()
        snapshot_v1 = self.insert_batch1()
        snapshot_v2 = self.insert_batch2()
        self.time_travel_test(snapshot_v1, snapshot_v2)
        
        print("\n" + "="*80)
        print("✅ TESTE DE TIME TRAVEL COMPLETO")
        print("="*80)
        
        self.spark.stop()


if __name__ == "__main__":
    tt = TimeTravel()
    tt.run()
