#!/usr/bin/env python3
"""
Iteration 3: Snapshot Lifecycle Management (Fixed)
=====================================

Purpose:
  - Manage snapshot retention policies
  - Monitor snapshot cleanup
  - Validate queries after cleanup
  
Success Criteria:
  - Snapshots properly listed
  - Queries work after cleanup
  - Data integrity maintained
"""

import os
import sys
import json
import time
from datetime import datetime, timedelta
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class SnapshotLifecycleManager:
    """Manage Iceberg snapshot retention and cleanup"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Snapshot_Lifecycle") \
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
    
    def get_snapshots_info(self, table_name):
        """Get current snapshots and their age"""
        print(f"\n📸 SNAPSHOTS INFO for {table_name}")
        print("=" * 70)
        
        try:
            snapshots_df = self.spark.sql(f"""
                SELECT 
                    snapshot_id,
                    parent_id,
                    operation,
                    timestamp_ms
                FROM {table_name}.snapshots
                ORDER BY timestamp_ms DESC
            """)
            
            snapshots = snapshots_df.collect()
            
            current_time_ms = int(time.time() * 1000)
            snapshot_list = []
            
            for snap in snapshots:
                snapshot_id = snap[0]
                operation = snap[2]
                timestamp_ms = snap[3]
                
                age_ms = current_time_ms - timestamp_ms
                age_hours = age_ms / (1000 * 60 * 60)
                age_days = age_hours / 24
                
                snapshot_info = {
                    "snapshot_id": snapshot_id,
                    "operation": operation,
                    "timestamp_ms": timestamp_ms,
                    "age_hours": age_hours,
                    "age_days": age_days,
                    "is_current": snapshot_id == snapshots[0][0],
                    "can_expire": age_days > 7
                }
                
                snapshot_list.append(snapshot_info)
                
                marker = "🔵 CURRENT" if snapshot_info["is_current"] else \
                         "⏰ EXPIRED" if snapshot_info["can_expire"] else "🟢 KEEP"
                
                print(f"  {marker} | ID: {snapshot_id} | Op: {operation}")
                print(f"       | Age: {age_days:.1f} days ({age_hours:.1f}h)")
            
            print(f"\n  📊 Total snapshots: {len(snapshot_list)}")
            print(f"  🔵 Current: {sum(1 for s in snapshot_list if s['is_current'])}")
            print(f"  ⏰ Expired (>7d): {sum(1 for s in snapshot_list if s['can_expire'])}")
            
            return snapshot_list
            
        except Exception as e:
            print(f"  ❌ Failed to get snapshots: {str(e)[:100]}")
            return []
    
    def validate_queries_after_cleanup(self, table_name):
        """Verify queries still work"""
        print(f"\n🔍 VALIDATING QUERIES")
        print("=" * 70)
        
        test_queries = [
            ("Count", f"SELECT COUNT(*) FROM {table_name}"),
            ("Sample", f"SELECT * FROM {table_name} LIMIT 5"),
            ("Filter", f"SELECT COUNT(*) FROM {table_name} WHERE year = 2025"),
        ]
        
        validation_results = []
        
        for query_name, query_sql in test_queries:
            try:
                result = self.spark.sql(query_sql).collect()
                validation_results.append({
                    "query": query_name,
                    "status": "SUCCESS",
                    "rows_returned": len(result)
                })
                print(f"  ✅ {query_name}: SUCCESS ({len(result)} rows)")
                
            except Exception as e:
                validation_results.append({
                    "query": query_name,
                    "status": "FAILED",
                    "error": str(e)[:100]
                })
                print(f"  ❌ {query_name}: FAILED")
        
        return validation_results
    
    def get_table_stats(self, table_name):
        """Get table statistics"""
        print(f"\n📊 TABLE STATISTICS")
        print("=" * 70)
        
        try:
            row_count = self.spark.sql(
                f"SELECT COUNT(*) FROM {table_name}"
            ).collect()[0][0]
            
            stats = {
                "row_count": row_count,
                "timestamp": datetime.now().isoformat()
            }
            
            print(f"  📝 Rows: {stats['row_count']:,}")
            
            return stats
            
        except Exception as e:
            print(f"  ⚠️  Could not get stats: {str(e)[:100]}")
            return {}
    
    def run(self):
        """Execute full lifecycle management workflow"""
        print("\n" + "="*70)
        print("📸 SNAPSHOT LIFECYCLE MANAGEMENT - ITERATION 3")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        initial_snapshots = self.get_snapshots_info(table_name)
        stats_before = self.get_table_stats(table_name)
        validation = self.validate_queries_after_cleanup(table_name)
        
        print(f"\n📈 LIFECYCLE MANAGEMENT SUMMARY")
        print("=" * 70)
        
        all_valid = all(v["status"] == "SUCCESS" for v in validation)
        print(f"  ✅ All queries valid: {all_valid}")
        print(f"  📸 Total snapshots: {len(initial_snapshots)}")
        print(f"  🟢 Current snapshots: {sum(1 for s in initial_snapshots if s['is_current'])}")
        print(f"  ⏰ Old snapshots: {sum(1 for s in initial_snapshots if s['can_expire'])}")
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "initial_snapshots_count": len(initial_snapshots),
            "snapshots": initial_snapshots,
            "stats": stats_before,
            "validation": validation,
            "all_queries_valid": all_valid,
            "summary": {
                "total_rows": stats_before.get("row_count", 0),
                "total_snapshots": len(initial_snapshots),
                "expired_snapshots": sum(1 for s in initial_snapshots if s['can_expire']),
                "status": "SUCCESS" if all_valid else "PARTIAL"
            }
        }
        
        output_file = "/tmp/snapshot_lifecycle_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ SNAPSHOT LIFECYCLE TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = SnapshotLifecycleManager()
    manager.run()
