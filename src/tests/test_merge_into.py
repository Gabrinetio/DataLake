from pyspark.sql import SparkSession
from pyspark.sql.functions import col, lit
from src.config import get_spark_s3_config
import sys

class MergeIntoUpsert:
    """Valida MERGE INTO para UPSERT operations"""
    
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
            .appName("IcebergMergeInto") \
            .configs(spark_config) \
            .getOrCreate()
    
    def setup_tables(self):
        """Cria tabelas de teste"""
        
        print("\n" + "="*60)
        print("SETUP: MERGE INTO Test")
        print("="*60)
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.inventory")
        except:
            pass
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.inventory_updates")
        except:
            pass
        
        # Tabela principal
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.inventory (
            product_id STRING,
            quantity INT,
            price DOUBLE,
            updated_at TIMESTAMP,
            year INT,
            month INT
        )
        USING iceberg
        PARTITIONED BY (year, month)
        """)
        
        # Tabela de updates
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.inventory_updates (
            product_id STRING,
            quantity INT,
            price DOUBLE,
            updated_at TIMESTAMP
        )
        USING parquet
        """)
        
        print("✓ Tabelas criadas")
    
    def initial_load(self):
        """Carrega dados iniciais"""
        
        print("\n" + "="*60)
        print("INITIAL LOAD: 5 produtos")
        print("="*60)
        
        from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, TimestampType
        
        schema = StructType([
            StructField("product_id", StringType(), True),
            StructField("quantity", IntegerType(), True),
            StructField("price", DoubleType(), True),
            StructField("updated_at", TimestampType(), True),
            StructField("year", IntegerType(), True),
            StructField("month", IntegerType(), True),
        ])
        
        from datetime import datetime
        
        df = self.spark.createDataFrame([
            ("PROD_001", 100, 49.99, datetime(2025, 12, 7, 10, 0, 0), 2025, 12),
            ("PROD_002", 50, 99.99, datetime(2025, 12, 7, 10, 0, 0), 2025, 12),
            ("PROD_003", 200, 29.99, datetime(2025, 12, 7, 10, 0, 0), 2025, 12),
            ("PROD_004", 75, 149.99, datetime(2025, 12, 7, 10, 0, 0), 2025, 12),
            ("PROD_005", 30, 199.99, datetime(2025, 12, 7, 10, 0, 0), 2025, 12),
        ], schema)
        
        df.writeTo("hadoop_prod.default.inventory").append()
        
        print("✓ Dados iniciais carregados")
        
        self.spark.sql("SELECT COUNT(*) as cnt FROM hadoop_prod.default.inventory").show()
    
    def prepare_updates(self):
        """Prepara dados de update"""
        
        print("\n" + "="*60)
        print("PREPARE UPDATES: 3 atualizações + 2 novos")
        print("="*60)
        
        from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, TimestampType
        from datetime import datetime
        
        schema = StructType([
            StructField("product_id", StringType(), True),
            StructField("quantity", IntegerType(), True),
            StructField("price", DoubleType(), True),
            StructField("updated_at", TimestampType(), True),
        ])
        
        updates = self.spark.createDataFrame([
            ("PROD_001", 50, 45.99, datetime(2025, 12, 7, 11, 0, 0)),    # UPDATE
            ("PROD_002", 25, 99.99, datetime(2025, 12, 7, 11, 0, 0)),    # UPDATE
            ("PROD_003", 200, 29.99, datetime(2025, 12, 7, 11, 0, 0)),   # UPDATE
            ("PROD_006", 100, 79.99, datetime(2025, 12, 7, 11, 0, 0)),   # NEW
            ("PROD_007", 60, 89.99, datetime(2025, 12, 7, 11, 0, 0)),    # NEW
        ], schema)
        
        updates.write.mode("overwrite").saveAsTable("inventory_updates")
        
        print("✓ Updates preparados")
        
        self.spark.sql("SELECT * FROM inventory_updates").show()
    
    def merge_operation(self):
        """Executa MERGE INTO"""
        
        print("\n" + "="*60)
        print("MERGE INTO OPERATION")
        print("="*60)
        
        merge_sql = """
        MERGE INTO hadoop_prod.default.inventory t
        USING inventory_updates s
        ON t.product_id = s.product_id
        WHEN MATCHED THEN
            UPDATE SET 
                t.quantity = s.quantity,
                t.price = s.price,
                t.updated_at = s.updated_at
        WHEN NOT MATCHED THEN
            INSERT (product_id, quantity, price, updated_at, year, month)
            VALUES (s.product_id, s.quantity, s.price, s.updated_at, 2025, 12)
        """
        
        self.spark.sql(merge_sql)
        print("✓ MERGE executado com sucesso")
    
    def validate_merge(self):
        """Valida resultado do merge"""
        
        print("\n" + "="*60)
        print("VALIDATION: Antes vs Depois")
        print("="*60)
        
        print("\n📊 ESTADO FINAL (após MERGE):")
        self.spark.sql("""
        SELECT 
            product_id, 
            quantity, 
            price, 
            updated_at
        FROM hadoop_prod.default.inventory
        ORDER BY product_id
        """).show(truncate=False)
        
        count = self.spark.sql("SELECT COUNT(*) as cnt FROM hadoop_prod.default.inventory").collect()[0]["cnt"]
        print(f"\n✓ Total registros após MERGE: {count}")
        print(f"  - Esperado: 7 (5 iniciais + 2 novos)")
        print(f"  - Status: {'✅ OK' if count == 7 else '❌ ERRO'}")
    
    def run(self):
        """Executa teste completo"""
        
        print("\n" + "="*80)
        print("ITERATION 2 - MERGE INTO (UPSERT) VALIDATION")
        print("="*80)
        
        self.setup_tables()
        self.initial_load()
        self.prepare_updates()
        self.merge_operation()
        self.validate_merge()
        
        print("\n" + "="*80)
        print("✅ MERGE INTO TEST COMPLETO")
        print("="*80)
        
        self.spark.stop()


if __name__ == "__main__":
    merge = MergeIntoUpsert()
    merge.run()
