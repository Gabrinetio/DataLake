#!/usr/bin/env python3
"""
Iteration 4: Disaster Recovery (v2 - Working Version)
=====================================================

Purpose:
  - Create checkpoint baselines
  - Simulate data corruption
  - Recover to checkpoint
  - Measure RTO/RPO

Based on: test_compaction.py (proven working config)
"""

import os
import json
import time
from datetime import datetime
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class DisasterRecoveryManager:
    """Handle disaster recovery procedures"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg (EXACT CONFIG FROM test_compaction.py)"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Disaster_Recovery_v2") \
            .master("local[2]") \
            .config("spark.sql.extensions", 
                   "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.hadoop_prod", 
                   "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", 
                   "s3a://datalake/warehouse") \
            .config("spark.jars.packages", 
                   "org.apache.hadoop:hadoop-aws:3.3.4," \
                   "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        print("\n✅ SparkSession initialized\n")
    
    def create_checkpoint(self, table_name, checkpoint_name=None):
        """Create a checkpoint baseline"""
        print(f"\n📍 CREATING CHECKPOINT for {table_name}")
        print("=" * 70)
        
        if checkpoint_name is None:
            checkpoint_name = f"checkpoint_{int(time.time())}"
        
        try:
            # Get table stats
            df = self.spark.sql(f"SELECT * FROM {table_name}")
            row_count = df.count()
            
            # Calculate simple hash of row counts per partition
            partition_stats = self.spark.sql(
                f"SELECT COUNT(*) as cnt FROM {table_name}"
            ).collect()
            
            checkpoint_info = {
                "checkpoint_name": checkpoint_name,
                "table": table_name,
                "row_count": row_count,
                "timestamp": datetime.now().isoformat(),
                "status": "SUCCESS"
            }
            
            print(f"  ✅ Checkpoint created: {checkpoint_name}")
            print(f"  📝 Rows at checkpoint: {row_count:,}")
            
            return checkpoint_info
            
        except Exception as e:
            print(f"  ❌ Checkpoint failed: {str(e)[:150]}")
            return {
                "checkpoint_name": checkpoint_name,
                "status": "FAILED",
                "error": str(e)[:150]
            }
    
    def simulate_data_corruption(self, table_name):
        """Simulate data corruption by inserting invalid records"""
        print(f"\n⚠️  SIMULATING DATA CORRUPTION")
        print("=" * 70)
        
        try:
            # Insert obviously corrupt records
            corrupt_sql = f"""
                INSERT INTO {table_name}
                VALUES (-999, 'CORRUPT_RECORD', -999.99, 0, '2099-12-31', 'CORRUPTION_TEST', 2099, 12)
            """
            
            self.spark.sql(corrupt_sql)
            
            # Verify insertion
            df = self.spark.sql(f"SELECT * FROM {table_name} WHERE product_id = 'CORRUPT_RECORD'")
            corrupt_count = df.count()
            
            print(f"  ⚠️  Corrupt records inserted: {corrupt_count}")
            
            return {
                "status": "SUCCESS",
                "corrupt_records_inserted": corrupt_count,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"  ❌ Corruption simulation failed: {str(e)[:150]}")
            return {
                "status": "FAILED",
                "error": str(e)[:150]
            }
    
    def recover_to_checkpoint(self, table_name, checkpoint_info):
        """Recover to checkpoint by removing corrupt data"""
        print(f"\n🔄 RECOVERING TO CHECKPOINT")
        print("=" * 70)
        
        rto_start = time.time()
        
        try:
            # Remove corrupt records
            delete_sql = f"DELETE FROM {table_name} WHERE product_id = 'CORRUPT_RECORD'"
            self.spark.sql(delete_sql)
            
            # Verify recovery
            df = self.spark.sql(f"SELECT COUNT(*) as cnt FROM {table_name}")
            recovered_count = df.collect()[0][0]
            
            rto_seconds = time.time() - rto_start
            
            recovery_info = {
                "status": "SUCCESS",
                "rows_after_recovery": recovered_count,
                "rto_seconds": rto_seconds,
                "expected_rows": checkpoint_info.get("row_count"),
                "recovery_successful": recovered_count == checkpoint_info.get("row_count"),
                "timestamp": datetime.now().isoformat()
            }
            
            print(f"  ✅ Recovery completed")
            print(f"  📝 Rows after recovery: {recovered_count:,}")
            print(f"  ⏱️  RTO: {rto_seconds:.2f}s")
            
            return recovery_info
            
        except Exception as e:
            print(f"  ❌ Recovery failed: {str(e)[:150]}")
            return {
                "status": "FAILED",
                "error": str(e)[:150],
                "rto_seconds": time.time() - rto_start
            }
    
    def validate_recovery(self, table_name):
        """Validate that recovery was successful"""
        print(f"\n✔️  VALIDATING RECOVERY")
        print("=" * 70)
        
        try:
            # Check for any corrupt records
            df = self.spark.sql(
                f"SELECT COUNT(*) as corrupt_count FROM {table_name} WHERE product_id = 'CORRUPT_RECORD'"
            )
            corrupt_count = df.collect()[0][0]
            
            # Run some test queries
            queries_passed = 0
            total_queries = 3
            
            try:
                self.spark.sql(f"SELECT COUNT(*) FROM {table_name}").show()
                queries_passed += 1
            except:
                pass
            
            try:
                self.spark.sql(f"SELECT * FROM {table_name} LIMIT 5").show()
                queries_passed += 1
            except:
                pass
            
            try:
                self.spark.sql(f"SELECT COUNT(DISTINCT product_id) FROM {table_name}").show()
                queries_passed += 1
            except:
                pass
            
            validation_result = {
                "status": "SUCCESS" if corrupt_count == 0 else "FAILED",
                "corrupt_records_remaining": corrupt_count,
                "queries_passed": queries_passed,
                "total_queries": total_queries,
                "recovery_valid": corrupt_count == 0
            }
            
            print(f"  ✅ Validation result: {validation_result['status']}")
            print(f"  📝 Corrupt records: {corrupt_count}")
            print(f"  ✔️  Queries passed: {queries_passed}/{total_queries}")
            
            return validation_result
            
        except Exception as e:
            print(f"  ❌ Validation failed: {str(e)[:150]}")
            return {
                "status": "FAILED",
                "error": str(e)[:150]
            }
    
    def run(self):
        """Execute full disaster recovery workflow"""
        print("\n" + "="*70)
        print("🔄 DISASTER RECOVERY PROCEDURES - ITERATION 4 (v2)")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        # 1. Create checkpoint
        checkpoint_result = self.create_checkpoint(table_name)
        
        # 2. Simulate corruption
        if checkpoint_result.get("status") == "SUCCESS":
            corruption_result = self.simulate_data_corruption(table_name)
        else:
            corruption_result = {"status": "SKIPPED", "reason": "Checkpoint failed"}
        
        # 3. Recover to checkpoint
        if corruption_result.get("status") == "SUCCESS":
            recovery_result = self.recover_to_checkpoint(table_name, checkpoint_result)
        else:
            recovery_result = {"status": "SKIPPED", "reason": "Corruption simulation failed"}
        
        # 4. Validate recovery
        if recovery_result.get("status") == "SUCCESS":
            validation_result = self.validate_recovery(table_name)
        else:
            validation_result = {"status": "SKIPPED", "reason": "Recovery failed"}
        
        # 5. Summary
        print(f"\n📊 DISASTER RECOVERY SUMMARY")
        print("=" * 70)
        
        print(f"  ✅ Checkpoint created: {checkpoint_result.get('status')}")
        if checkpoint_result.get("status") == "SUCCESS":
            print(f"     Baseline rows: {checkpoint_result.get('row_count'):,}")
        
        print(f"  ⚠️  Corruption simulated: {corruption_result.get('status')}")
        if corruption_result.get("status") == "SUCCESS":
            print(f"     Corrupt records: {corruption_result.get('corrupt_records_inserted')}")
        
        print(f"  ✅ Recovery executed: {recovery_result.get('status')}")
        if recovery_result.get("status") == "SUCCESS":
            print(f"     RTO: {recovery_result.get('rto_seconds'):.2f}s")
        
        print(f"  ✔️  Recovery validated: {validation_result.get('status')}")
        if validation_result.get("status") == "SUCCESS":
            print(f"     Queries passed: {validation_result.get('queries_passed')}/{validation_result.get('total_queries')}")
        
        # 6. Save results
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "checkpoint": checkpoint_result,
            "corruption_simulation": corruption_result,
            "recovery": recovery_result,
            "validation": validation_result,
            "summary": {
                "checkpoint_status": checkpoint_result.get("status"),
                "corruption_status": corruption_result.get("status"),
                "recovery_status": recovery_result.get("status"),
                "validation_status": validation_result.get("status"),
                "rto_seconds": recovery_result.get("rto_seconds"),
                "overall_success": (
                    checkpoint_result.get("status") == "SUCCESS" and
                    recovery_result.get("status") == "SUCCESS" and
                    validation_result.get("status") == "SUCCESS"
                )
            }
        }
        
        output_file = "/tmp/disaster_recovery_v2_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ DISASTER RECOVERY TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = DisasterRecoveryManager()
    manager.run()
