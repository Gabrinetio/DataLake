from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col, expr, rand, when, lit, concat, round,
    date_add, to_date, year, month, dayofmonth
)
import sys
from datetime import datetime, timedelta
from src.config import get_spark_s3_config

class DataGenerator:
    """Gera datasets de teste para benchmark de Iceberg/Spark"""
    
    def __init__(self, num_records=100000, num_products=1000, num_regions=50):
        self.num_records = num_records
        self.num_products = num_products
        self.num_regions = num_regions
        
        # Configurar SparkSession com Iceberg
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("IcebergDataGenerator") \
            .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
            .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .getOrCreate()
    
    def generate_sales_data(self):
        """Gera dataset de vendas realista"""
        
        print(f"Gerando {self.num_records:,} registros de vendas...")
        
        # Base data aleatória entre 2022-01-01 e 2024-12-31
        df = self.spark.range(self.num_records) \
            .select(
                (col("id") + 1).alias("transaction_id"),
                
                # Produto
                expr(f"concat('PROD_', cast(rand() * {self.num_products} as int))").alias("product_id"),
                expr(f"concat('Product_', cast(rand() * {self.num_products} as int))").alias("product_name"),
                
                # Região
                expr(f"concat('REGION_', cast(rand() * {self.num_regions} as int))").alias("region"),
                
                # Valores
                expr("round(rand() * 5000, 2)").alias("sale_amount"),
                expr("cast(rand() * 100 as int) + 1").alias("quantity"),
                
                # Data aleatória
                expr("date_add('2022-01-01', cast(rand() * 1095 as int))").alias("sale_date"),
                
                # Categoria (distribuição enviesada)
                when(rand() < 0.4, "Electronics")
                    .when(rand() < 0.7, "Clothing")
                    .when(rand() < 0.85, "Food")
                    .otherwise("Other").alias("category"),
                
                # Salesman (distribuição enviesada)
                expr("concat('SALES_', cast(rand() * 500 as int))").alias("salesman_id"),
                
                # Timestamp
                expr("cast(concat(sale_date, ' ', cast(cast(rand() * 24 as int) as string), ':00:00') as timestamp)")
                    .alias("sale_timestamp")
            )
        
        # Adicionar colunas de partição
        df = df \
            .withColumn("year", year(col("sale_date"))) \
            .withColumn("month", month(col("sale_date"))) \
            .withColumn("day", dayofmonth(col("sale_date")))
        
        return df
    
    def generate_inventory_data(self):
        """Gera dataset de inventário"""
        
        print(f"Gerando dados de inventário para {self.num_products:,} produtos...")
        
        df = self.spark.range(self.num_products) \
            .select(
                concat("PROD_", col("id")).alias("product_id"),
                concat("Product_", col("id")).alias("product_name"),
                expr("round(100 + rand() * 10000, 2)").alias("unit_cost"),
                expr("cast(rand() * 10000 as int)").alias("stock_quantity"),
                expr("cast(rand() * 5000 as int)").alias("reorder_point"),
                expr(f"concat('WAREHOUSE_', cast(rand() * 10 as int))").alias("warehouse_location"),
                expr("current_timestamp()").alias("last_updated")
            )
        
        return df
    
    def generate_customers_data(self):
        """Gera dataset de clientes"""
        
        num_customers = int(self.num_records * 0.01)  # 1% do volume de vendas
        print(f"Gerando dados de {num_customers:,} clientes...")
        
        df = self.spark.range(num_customers) \
            .select(
                (col("id") + 1).alias("customer_id"),
                concat("CUST_", col("id")).alias("customer_code"),
                concat("Customer_", col("id")).alias("customer_name"),
                expr(f"concat('REGION_', cast(rand() * {self.num_regions} as int))").alias("region"),
                expr("round(rand() * 1000000, 2)").alias("lifetime_value"),
                when(rand() < 0.7, "Active").otherwise("Inactive").alias("status"),
                expr("date_add('2020-01-01', cast(rand() * 1460 as int))").alias("signup_date"),
                expr("current_timestamp()").alias("last_activity")
            )
        
        return df
    
    def create_table_vendas_particionada(self):
        """Cria tabela Iceberg particionada de vendas"""
        
        print("\n" + "="*60)
        print("Criando tabela: hadoop_prod.default.vendas_teste")
        print("="*60)
        
        # Remover se existir
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.vendas_teste")
            print("✓ Tabela anterior removida")
        except:
            pass
        
        # Criar tabela
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.vendas_teste (
            transaction_id BIGINT,
            product_id STRING,
            product_name STRING,
            region STRING,
            sale_amount DOUBLE,
            quantity INT,
            sale_date DATE,
            category STRING,
            salesman_id STRING,
            sale_timestamp TIMESTAMP
        )
        USING iceberg
        PARTITIONED BY (year INT, month INT, day INT)
        """)
        
        print("✓ Tabela criada com sucesso")
        
        # Gerar dados
        df_vendas = self.generate_sales_data()
        
        # Inserir
        print(f"\nInserindo {self.num_records:,} registros...")
        df_vendas.writeTo("hadoop_prod.default.vendas_teste").append()
        print("✓ Dados inseridos com sucesso")
        
        # Estatísticas
        self.spark.sql("SELECT COUNT(*) as total_rows FROM hadoop_prod.default.vendas_teste").show()
        self.spark.sql("SELECT year, month, COUNT(*) FROM hadoop_prod.default.vendas_teste GROUP BY year, month ORDER BY year, month").show()
        
        return df_vendas
    
    def create_table_inventario(self):
        """Cria tabela Iceberg de inventário"""
        
        print("\n" + "="*60)
        print("Criando tabela: hadoop_prod.default.inventario")
        print("="*60)
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.inventario")
            print("✓ Tabela anterior removida")
        except:
            pass
        
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.inventario (
            product_id STRING,
            product_name STRING,
            unit_cost DOUBLE,
            stock_quantity INT,
            reorder_point INT,
            warehouse_location STRING,
            last_updated TIMESTAMP
        )
        USING iceberg
        """)
        
        print("✓ Tabela criada com sucesso")
        
        df_inventario = self.generate_inventory_data()
        df_inventario.writeTo("hadoop_prod.default.inventario").append()
        print("✓ Dados inseridos com sucesso")
        
        self.spark.sql("SELECT COUNT(*) as total_products FROM hadoop_prod.default.inventario").show()
        
        return df_inventario
    
    def create_table_clientes(self):
        """Cria tabela Iceberg de clientes"""
        
        print("\n" + "="*60)
        print("Criando tabela: hadoop_prod.default.clientes")
        print("="*60)
        
        try:
            self.spark.sql("DROP TABLE IF EXISTS hadoop_prod.default.clientes")
            print("✓ Tabela anterior removida")
        except:
            pass
        
        self.spark.sql("""
        CREATE TABLE hadoop_prod.default.clientes (
            customer_id BIGINT,
            customer_code STRING,
            customer_name STRING,
            region STRING,
            lifetime_value DOUBLE,
            status STRING,
            signup_date DATE,
            last_activity TIMESTAMP
        )
        USING iceberg
        """)
        
        print("✓ Tabela criada com sucesso")
        
        df_clientes = self.generate_customers_data()
        df_clientes.writeTo("hadoop_prod.default.clientes").append()
        print("✓ Dados inseridos com sucesso")
        
        self.spark.sql("SELECT COUNT(*) as total_customers FROM hadoop_prod.default.clientes").show()
        
        return df_clientes
    
    def generate_all(self):
        """Cria todas as tabelas de teste"""
        
        print("\n" + "="*80)
        print("GERADOR DE DADOS PARA TESTE DE BENCHMARK - ICEBERG")
        print("="*80)
        print(f"Timestamp: {datetime.now().isoformat()}")
        print(f"Registros de vendas: {self.num_records:,}")
        print(f"Produtos: {self.num_products:,}")
        print(f"Regiões: {self.num_regions:,}")
        print("="*80 + "\n")
        
        self.create_table_vendas_particionada()
        self.create_table_inventario()
        self.create_table_clientes()
        
        print("\n" + "="*80)
        print("✅ GERAÇÃO DE DADOS CONCLUÍDA COM SUCESSO!")
        print("="*80)
        
        # Resumo final
        self.spark.sql("""
        SELECT 
            'vendas_teste' as table_name,
            COUNT(*) as record_count,
            CURRENT_TIMESTAMP() as generated_at
        FROM hadoop_prod.default.vendas_teste
        UNION ALL
        SELECT
            'inventario',
            COUNT(*),
            CURRENT_TIMESTAMP()
        FROM hadoop_prod.default.inventario
        UNION ALL
        SELECT
            'clientes',
            COUNT(*),
            CURRENT_TIMESTAMP()
        FROM hadoop_prod.default.clientes
        """).show(truncate=False)
        
        self.spark.stop()


if __name__ == "__main__":
    # Aceitar argumentos de linha de comando
    num_records = int(sys.argv[1]) if len(sys.argv) > 1 else 100_000
    num_products = int(sys.argv[2]) if len(sys.argv) > 2 else 1000
    num_regions = int(sys.argv[3]) if len(sys.argv) > 3 else 50
    
    generator = DataGenerator(num_records, num_products, num_regions)
    generator.generate_all()
