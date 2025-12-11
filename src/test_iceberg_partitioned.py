#!/usr/bin/env python3

from pyspark.sql import SparkSession
from pyspark.sql.functions import year, month, dayofmonth
from src.config import get_spark_s3_config

# Configurações S3 e Iceberg carregadas de .env via src.config
spark_config = get_spark_s3_config()

# Adicionar configurações específicas do Iceberg
spark_config.update({
    'spark.sql.catalog.spark_catalog.type': 'hadoop',
    'spark.hadoop.fs.s3a.connection.ssl.enabled': 'false',
})

# Criar SparkSession com configurações
spark = SparkSession.builder \
    .appName('TestIcebergPartitioned') \
    .configs(spark_config) \
    .getOrCreate()

try:
    print('Criando tabela Iceberg particionada...')

    # Criar tabela Iceberg com particionamento por data
    spark.sql('''
        CREATE TABLE IF NOT EXISTS spark_catalog.default.vendas_particionadas (
            id INT,
            produto STRING,
            categoria STRING,
            valor DOUBLE,
            quantidade INT,
            data_venda DATE,
            ano INT,
            mes INT,
            dia INT
        ) USING iceberg
        PARTITIONED BY (ano, mes)
        LOCATION 's3a://datalake/warehouse/default/vendas_particionadas'
    ''')

    print('Tabela particionada criada com sucesso!')

    # Inserir dados de teste com datas variadas
    print('Inserindo dados particionados...')
    spark.sql('''
        INSERT INTO spark_catalog.default.vendas_particionadas VALUES
        (1, 'Notebook Dell', 'Eletrônicos', 3500.00, 1, '2025-01-15', 2025, 1, 15),
        (2, 'Mouse Logitech', 'Acessórios', 150.00, 2, '2025-01-20', 2025, 1, 20),
        (3, 'Teclado Mecânico', 'Acessórios', 450.00, 1, '2025-02-10', 2025, 2, 10),
        (4, 'Monitor 27"', 'Eletrônicos', 1200.00, 1, '2025-02-15', 2025, 2, 15),
        (5, 'Cadeira Gamer', 'Móveis', 800.00, 1, '2025-03-05', 2025, 3, 5),
        (6, 'Headset RGB', 'Acessórios', 250.00, 1, '2025-03-12', 2025, 3, 12)
    ''')

    print('Dados inseridos com sucesso!')

    # Consultar dados
    print('Consultando todos os dados:')
    result = spark.sql('SELECT * FROM spark_catalog.default.vendas_particionadas ORDER BY data_venda')
    result.show()

    # Consultar dados particionados (filtrando por mês)
    print('Consultando vendas de janeiro (partição ano=2025, mes=1):')
    result_jan = spark.sql('''
        SELECT produto, valor, quantidade, data_venda
        FROM spark_catalog.default.vendas_particionadas
        WHERE ano = 2025 AND mes = 1
        ORDER BY data_venda
    ''')
    result_jan.show()

    # Consultar dados particionados (filtrando por fevereiro)
    print('Consultando vendas de fevereiro (partição ano=2025, mes=2):')
    result_fev = spark.sql('''
        SELECT produto, valor, quantidade, data_venda
        FROM spark_catalog.default.vendas_particionadas
        WHERE ano = 2025 AND mes = 2
        ORDER BY data_venda
    ''')
    result_fev.show()

    # Estatísticas por categoria
    print('Estatísticas por categoria:')
    stats = spark.sql('''
        SELECT
            categoria,
            COUNT(*) as total_vendas,
            SUM(valor * quantidade) as valor_total,
            AVG(valor) as valor_medio
        FROM spark_catalog.default.vendas_particionadas
        GROUP BY categoria
        ORDER BY valor_total DESC
    ''')
    stats.show()

    print('Teste Iceberg particionado: SUCESSO')

except Exception as e:
    print(f'Erro no teste Iceberg particionado: {e}')
    import traceback
    traceback.print_exc()

finally:
    spark.stop()