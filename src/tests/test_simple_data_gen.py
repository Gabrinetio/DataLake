from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, rand, when, lit, concat, round, date_add, year, month, dayofmonth
from src.config import get_spark_s3_config
import sys

class SimplifiedDataGenerator:
    """Versão simplificada do gerador que reduz problemas de memória"""
    
    def __init__(self, num_records=10000):
        self.num_records = num_records
        
        # Configurações S3 carregadas de .env
        spark_config = get_spark_s3_config()
        
        # Adicionar configurações específicas para Iceberg
        spark_config.update({
            "spark.sql.catalog.hadoop_prod": "org.apache.iceberg.spark.SparkCatalog",
            "spark.sql.catalog.hadoop_prod.type": "hadoop",
            "spark.hadoop.fs.s3a.connection.ssl.enabled": "false",
            "spark.sql.extensions": "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
            "spark.sql.parquet.compression.codec": "snappy",
            "spark.memory.fraction": "0.8",
        })
        
        # Configurar SparkSession com Iceberg - memory otimizado
        self.spark = SparkSession.builder \
            .appName("IcebergSimpleGenerator") \
            .configs(spark_config) \
            .getOrCreate()
    
    def create_table_vendas_small(self):
        """Cria tabela com dados pequenos para testes"""
        
        print("\n" + "="*60)
        print(f"Criando tabela: hadoop_prod.default.vendas_small")
        print(f"Registros: {self.num_records:,}")
        print("="*60)
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.vendas_small")
            print("✓ Tabela anterior removida")
        except:
            pass
        
        # Criar tabela
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.vendas_small (
            transaction_id BIGINT,
            product_id STRING,
            sale_amount DOUBLE,
            quantity INT,
            sale_date DATE,
            category STRING
        )
        USING iceberg
        PARTITIONED BY (year INT, month INT)
        """)
        
        print("✓ Tabela criada")
        
        # Gerar dados
        print(f"Gerando {self.num_records:,} registros...")
        df = self.spark.range(self.num_records) \
            .select(
                (col("id") + 1).alias("transaction_id"),
                expr("concat('PROD_', cast(rand() * 100 as int))").alias("product_id"),
                expr("round(rand() * 1000, 2)").alias("sale_amount"),
                expr("cast(rand() * 50 as int) + 1").alias("quantity"),
                expr("date_add('2023-01-01', cast(rand() * 365 as int))").alias("sale_date"),
                when(rand() < 0.4, "Electronics")
                    .when(rand() < 0.7, "Clothing")
                    .otherwise("Other").alias("category")
            )
        
        df = df \
            .withColumn("year", year(col("sale_date"))) \
            .withColumn("month", month(col("sale_date")))
        
        # Inserir dados
        print("Inserindo dados...")
        df.writeTo("hadoop_prod.default.vendas_small").append()
        print("✓ Dados inseridos")
        
        # Mostrar estatísticas
        self.spark.sql("SELECT COUNT(*) as total FROM hadoop_prod.default.vendas_small").show()
        self.spark.sql("""
        SELECT year, month, COUNT(*) as count 
        FROM hadoop_prod.default.vendas_small 
        GROUP BY year, month 
        ORDER BY year, month
        """).show()
        
        return df
    
    def run_simple_queries(self):
        """Executa queries de teste simples"""
        
        print("\n" + "="*60)
        print("Executando queries de teste...")
        print("="*60)
        
        # Query 1: Full scan
        print("\n1. Full Scan:")
        self.spark.sql("SELECT COUNT(*) FROM hadoop_prod.default.vendas_small").show()
        
        # Query 2: Filter
        print("\n2. Filter by month:")
        self.spark.sql("""
        SELECT COUNT(*), category FROM hadoop_prod.default.vendas_small
        WHERE month = 6
        GROUP BY category
        """).show()
        
        # Query 3: Aggregation
        print("\n3. Aggregation:")
        self.spark.sql("""
        SELECT 
            category,
            COUNT(*) as num_sales,
            ROUND(SUM(sale_amount), 2) as total_amount,
            ROUND(AVG(sale_amount), 2) as avg_amount
        FROM hadoop_prod.default.vendas_small
        GROUP BY category
        """).show()
    
    def generate(self):
        """Executa geração completa"""
        
        print("\n" + "="*80)
        print("GERADOR DE DADOS SIMPLIFICADO - ICEBERG")
        print("="*80)
        
        self.create_table_vendas_small()
        self.run_simple_queries()
        
        print("\n" + "="*80)
        print("✅ GERAÇÃO CONCLUÍDA COM SUCESSO!")
        print("="*80)
        
        self.spark.stop()


if __name__ == "__main__":
    num_records = int(sys.argv[1]) if len(sys.argv) > 1 else 50000
    generator = SimplifiedDataGenerator(num_records)
    generator.generate()
