#!/bin/bash
# Test CDC Pipeline directly

export SPARK_SUBMIT="/opt/spark/spark-3.5.7-bin-hadoop3/bin/spark-submit"

echo "Starting CDC test..."
$SPARK_SUBMIT \
  --master local[*] \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 2G \
  --executor-memory 2G \
  --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog \
  --conf spark.sql.catalog.spark_catalog.type=hadoop \
  --conf spark.sql.catalog.spark_catalog.warehouse=/home/datalake/warehouse \
  /home/datalake/test_cdc_pipeline.py

echo "CDC test completed"
