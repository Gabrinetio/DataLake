#!/bin/bash

# Teste de conectividade Spark + Hive Metastore

echo "=== Teste Spark + Hive Metastore ==="

# Criar tabela de teste no Hive
/opt/spark/default/bin/spark-sql --master local --conf spark.sql.catalogImplementation=hive << 'EOF'
CREATE DATABASE IF NOT EXISTS test_db;
USE test_db;
CREATE TABLE IF NOT EXISTS test_table (
    id INT,
    name STRING,
    value DOUBLE
) USING iceberg
PARTITIONED BY (id)
LOCATION 's3a://datalake/warehouse/test_db/test_table';

INSERT INTO test_table VALUES (1, 'test1', 1.0), (2, 'test2', 2.0);

SELECT * FROM test_table;
EOF

echo "=== Teste concluído ==="