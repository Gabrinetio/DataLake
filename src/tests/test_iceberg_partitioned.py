from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year, month
from src.config import get_spark_s3_config

# Configurar SparkSession com Iceberg
spark_config = get_spark_s3_config()
spark = SparkSession.builder \
    .appName("TestPartitioned") \
    .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
    .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .getOrCreate()

print("Criando tabela particionada...")

# Criar tabela particionada usando SQL
spark.sql("""
CREATE TABLE IF NOT EXISTS hadoop_prod.default.vendas_partitioned (
    id INT,
    produto STRING,
    valor DOUBLE,
    data_venda DATE
)
USING iceberg
PARTITIONED BY (ano INT, mes INT)
""")

print("Tabela criada!")

print("Inserindo dados...")

# Inserir dados de teste
spark.sql("""
INSERT INTO hadoop_prod.default.vendas_partitioned (id, produto, valor, data_venda, ano, mes)
VALUES
(1, 'Produto A', 100.0, CAST('2023-01-15' AS DATE), 2023, 1),
(2, 'Produto B', 200.0, CAST('2023-02-20' AS DATE), 2023, 2),
(3, 'Produto C', 150.0, CAST('2023-01-10' AS DATE), 2023, 1),
(4, 'Produto D', 300.0, CAST('2023-03-05' AS DATE), 2023, 3),
(5, 'Produto E', 250.0, CAST('2023-02-28' AS DATE), 2023, 2)
""")

print("Dados inseridos!")

print("Consultando dados...")
result = spark.sql("SELECT * FROM hadoop_prod.default.vendas_partitioned ORDER BY id")
result.show()

print("Testando particionamento...")
result_partitioned = spark.sql("SELECT * FROM hadoop_prod.default.vendas_partitioned WHERE ano = 2023 AND mes = 1")
result_partitioned.show()

spark.stop()