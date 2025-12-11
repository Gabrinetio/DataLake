#!/bin/bash
# PHASE 1 - AUTOMATED TEST EXECUTION
# Execute este script no servidor via SSH

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 PHASE 1 - AUTOMATED SPARK TEST EXECUTION           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd /home/datalake

# ====== TEST 1: CDC Pipeline ======
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "TEST 1/3: CDC Pipeline"
echo "═══════════════════════════════════════════════════════════════"
echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TEST1_START=$(date +%s)
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_cdc_pipeline.py
TEST1_EXIT=$?
TEST1_END=$(date +%s)
TEST1_DURATION=$((TEST1_END - TEST1_START))

if [ $TEST1_EXIT -eq 0 ]; then
  echo "✅ CDC Pipeline PASSED (${TEST1_DURATION}s)"
  ls -lh cdc_pipeline_results.json
else
  echo "❌ CDC Pipeline FAILED (Exit Code: $TEST1_EXIT)"
fi

# ====== TEST 2: RLAC Implementation ======
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "TEST 2/3: RLAC Implementation"
echo "═══════════════════════════════════════════════════════════════"
echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TEST2_START=$(date +%s)
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_rlac_implementation.py
TEST2_EXIT=$?
TEST2_END=$(date +%s)
TEST2_DURATION=$((TEST2_END - TEST2_START))

if [ $TEST2_EXIT -eq 0 ]; then
  echo "✅ RLAC Implementation PASSED (${TEST2_DURATION}s)"
  ls -lh rlac_implementation_results.json
else
  echo "❌ RLAC Implementation FAILED (Exit Code: $TEST2_EXIT)"
fi

# ====== TEST 3: BI Integration ======
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "TEST 3/3: BI Integration"
echo "═══════════════════════════════════════════════════════════════"
echo "Start Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

TEST3_START=$(date +%s)
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_bi_integration.py
TEST3_EXIT=$?
TEST3_END=$(date +%s)
TEST3_DURATION=$((TEST3_END - TEST3_START))

if [ $TEST3_EXIT -eq 0 ]; then
  echo "✅ BI Integration PASSED (${TEST3_DURATION}s)"
  ls -lh bi_integration_results.json
else
  echo "❌ BI Integration FAILED (Exit Code: $TEST3_EXIT)"
fi

# ====== SUMMARY ======
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "EXECUTION SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""

PASSED=0
FAILED=0

if [ $TEST1_EXIT -eq 0 ]; then
  echo "✅ Test 1 (CDC): PASSED (${TEST1_DURATION}s)"
  PASSED=$((PASSED + 1))
else
  echo "❌ Test 1 (CDC): FAILED"
  FAILED=$((FAILED + 1))
fi

if [ $TEST2_EXIT -eq 0 ]; then
  echo "✅ Test 2 (RLAC): PASSED (${TEST2_DURATION}s)"
  PASSED=$((PASSED + 1))
else
  echo "❌ Test 2 (RLAC): FAILED"
  FAILED=$((FAILED + 1))
fi

if [ $TEST3_EXIT -eq 0 ]; then
  echo "✅ Test 3 (BI): PASSED (${TEST3_DURATION}s)"
  PASSED=$((PASSED + 1))
else
  echo "❌ Test 3 (BI): FAILED"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "Results: $PASSED PASSED, $FAILED FAILED"
echo ""
echo "Generated files:"
ls -lh *_results.json 2>/dev/null || echo "No result files found"
echo ""
echo "✅ ALL TESTS COMPLETE"
echo "End Time: $(date '+%Y-%m-%d %H:%M:%S')"
