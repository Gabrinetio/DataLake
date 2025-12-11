#!/bin/bash
# Run all 3 PHASE 1 tests

export SPARK_SUBMIT="/opt/spark/spark-3.5.7-bin-hadoop3/bin/spark-submit"
cd /home/datalake

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TEST 1/3: CDC PIPELINE                                   ║"
echo "╚════════════════════════════════════════════════════════════╝"

SPARK_CONF="--conf spark.sql.warehouse.dir=/home/datalake/warehouse --conf spark.sql.catalog.spark_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.spark_catalog.type=hadoop --conf spark.sql.catalog.spark_catalog.warehouse=/home/datalake/warehouse"

${SPARK_SUBMIT} --master local[*] $SPARK_CONF \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 2G --executor-memory 2G \
  test_cdc_pipeline.py
CDC_EXIT=$?
if [ ${CDC_EXIT} -ne 0 ]; then
  echo "{\"status\": \"FAILED\", \"test\": \"CDC\", \"exit_code\": ${CDC_EXIT}}" > /tmp/cdc_pipeline_results.json
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TEST 2/3: RLAC IMPLEMENTATION                            ║"
echo "╚════════════════════════════════════════════════════════════╝"

${SPARK_SUBMIT} --master local[*] $SPARK_CONF \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 2G --executor-memory 2G \
  test_rlac_implementation.py
RLAC_EXIT=$?
if [ ${RLAC_EXIT} -ne 0 ]; then
  echo "{\"status\": \"FAILED\", \"test\": \"RLAC\", \"exit_code\": ${RLAC_EXIT}}" > /tmp/rlac_implementation_results.json
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TEST 3/3: BI INTEGRATION                                 ║"
echo "╚════════════════════════════════════════════════════════════╝"

${SPARK_SUBMIT} --master local[*] $SPARK_CONF \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G --executor-memory 4G \
  test_bi_integration.py
BI_EXIT=$?
if [ ${BI_EXIT} -ne 0 ]; then
  echo "{\"status\": \"FAILED\", \"test\": \"BI\", \"exit_code\": ${BI_EXIT}}" > /tmp/bi_integration_results.json
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ ALL TESTS COMPLETE"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Results generated (under /tmp):"
ls -lh /tmp/*_results.json 2>/dev/null || echo "No results found in /tmp"
