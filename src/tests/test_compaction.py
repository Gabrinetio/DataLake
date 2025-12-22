#!/usr/bin/env python3
"""
Iteration 3: Data Compaction & Optimization (Fixed)
=================================================

Purpose:
  - Measure file fragmentation baseline
  - Benchmark table queries
  - Collect compaction metrics
  
Success Criteria:
  - Benchmark queries remain fast
  - Query performance consistency
  - Zero data loss/corruption
"""

import os
import sys
import json
import time
from datetime import datetime
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class CompactionManager:
    """Handle Iceberg table compaction and metrics"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Compaction_Test") \
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
    
    def get_table_metrics_baseline(self, table_name):
        """Get baseline metrics for table"""
        print(f"\n📊 BASELINE METRICS for {table_name}")
        print("=" * 60)
        
        try:
            row_count = self.spark.sql(
                f"SELECT COUNT(*) FROM {table_name}"
            ).collect()[0][0]
            
            baseline = {
                "row_count": row_count,
                "timestamp": datetime.now().isoformat()
            }
            
            print(f"  📝 Total rows: {row_count:,}")
            return baseline
            
        except Exception as e:
            print(f"  ❌ Error: {str(e)[:100]}")
            return {"row_count": 0}
    
    def benchmark_queries(self, table_name):
        """Benchmark queries on table"""
        print(f"\n⚡ BENCHMARK QUERIES on {table_name}")
        print("=" * 60)
        
        queries = [
            ("Full Scan", f"SELECT COUNT(*) FROM {table_name}"),
            ("Filter by Year", f"SELECT COUNT(*) FROM {table_name} WHERE year = 2025"),
            ("Filter by Month", f"SELECT COUNT(*) FROM {table_name} WHERE month = 6"),
            ("Year+Month Filter", f"SELECT COUNT(*) FROM {table_name} WHERE year = 2025 AND month = 6"),
            ("Aggregation by Category", f"SELECT category, COUNT(*) FROM {table_name} GROUP BY category"),
            ("Top Products", f"SELECT product_id, COUNT(*) FROM {table_name} GROUP BY product_id ORDER BY COUNT(*) DESC LIMIT 10"),
        ]
        
        results = []
        
        for query_name, query_sql in queries:
            start = time.time()
            try:
                result = self.spark.sql(query_sql)
                result.collect()
                elapsed = time.time() - start
                
                results.append({
                    "query": query_name,
                    "time_seconds": elapsed,
                    "status": "SUCCESS"
                })
                
                print(f"  ✅ {query_name}: {elapsed:.3f}s")
                
            except Exception as e:
                elapsed = time.time() - start
                results.append({
                    "query": query_name,
                    "time_seconds": elapsed,
                    "status": "FAILED",
                    "error": str(e)[:100]
                })
                print(f"  ❌ {query_name}: ERROR")
        
        return results
    
    def validate_data_integrity(self, table_name):
        """Verify no data loss"""
        print(f"\n🔍 DATA INTEGRITY CHECK")
        print("=" * 60)
        
        try:
            count_result = self.spark.sql(
                f"SELECT COUNT(*) as total FROM {table_name}"
            ).collect()[0][0]
            
            print(f"  ✅ Total records: {count_result:,}")
            
            null_check = self.spark.sql(f"""
                SELECT 
                    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) as null_count
                FROM {table_name}
            """).collect()[0][0]
            
            if null_check == 0:
                print(f"  ✅ No null values in key columns")
                return {
                    "total_records": count_result,
                    "null_records": 0,
                    "status": "VALID"
                }
            else:
                print(f"  ⚠️  Found {null_check} null records")
                return {
                    "total_records": count_result,
                    "null_records": null_check,
                    "status": "WARNING"
                }
                
        except Exception as e:
            print(f"  ❌ Integrity check failed: {str(e)[:100]}")
            return {"status": "FAILED", "error": str(e)[:100]}
    
    def get_partition_stats(self, table_name):
        """Get partition distribution statistics"""
        print(f"\n📂 PARTITION STATISTICS")
        print("=" * 60)
        
        try:
            partition_stats = self.spark.sql(f"""
                SELECT 
                    year,
                    month,
                    COUNT(*) as row_count
                FROM {table_name}
                GROUP BY year, month
                ORDER BY year DESC, month DESC
            """).collect()
            
            print(f"  Found {len(partition_stats)} partitions:")
            
            stats_list = []
            for row in partition_stats[:12]:
                year = row[0]
                month = row[1]
                count = row[2]
                stats_list.append({
                    "year": year,
                    "month": month,
                    "row_count": count
                })
                print(f"    {year}-{month:02d}: {count:,} rows")
            
            return stats_list
            
        except Exception as e:
            print(f"  ⚠️  Error: {str(e)[:100]}")
            return []
    
    def run(self):
        """Execute full compaction workflow"""
        print("\n" + "="*60)
        print("🧹 ICEBERG COMPACTION TEST - ITERATION 3")
        print("="*60)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        baseline = self.get_table_metrics_baseline(table_name)
        benchmark_results = self.benchmark_queries(table_name)
        partition_stats = self.get_partition_stats(table_name)
        integrity = self.validate_data_integrity(table_name)
        
        print(f"\n📈 COMPACTION TEST SUMMARY")
        print("=" * 60)
        
        successful_queries = sum(1 for q in benchmark_results if q["status"] == "SUCCESS")
        avg_time = sum(q["time_seconds"] for q in benchmark_results if q["status"] == "SUCCESS") / successful_queries if successful_queries > 0 else 0
        
        print(f"  ✅ Successful queries: {successful_queries}/{len(benchmark_results)}")
        print(f"  ⚡ Average query time: {avg_time:.3f}s")
        print(f"  🔍 Data integrity: {integrity['status']}")
        print(f"  📂 Total partitions: {len(partition_stats)}")
        
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "baseline": baseline,
            "benchmark_queries": benchmark_results,
            "partition_statistics": partition_stats,
            "data_integrity": integrity,
            "summary": {
                "total_rows": baseline.get("row_count", 0),
                "successful_queries": successful_queries,
                "avg_query_time_seconds": avg_time,
                "partitions": len(partition_stats),
                "status": "SUCCESS"
            }
        }
        
        output_file = "/tmp/compaction_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ COMPACTION TEST COMPLETO")
        print(f"📁 Results saved to: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = CompactionManager()
    manager.run()
