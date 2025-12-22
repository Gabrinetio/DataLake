#!/usr/bin/env python3
"""
Iteration 3: Monitoring & Statistics Collection (Fixed)
===============================================

Purpose:
  - Collect comprehensive table statistics
  - Analyze query performance patterns
  - Identify optimization opportunities
  
Success Criteria:
  - Metrics logged consistently
  - Slow queries identified
  - Partition efficiency measured
  - Report generated
"""

import os
import sys
import json
import time
from datetime import datetime
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class MonitoringManager:
    """Monitor Iceberg table performance and statistics"""
    
    def __init__(self):
        """Initialize Spark session with Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Monitoring") \
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
    
    def collect_table_statistics(self, table_name):
        """Collect comprehensive table statistics"""
        print(f"\n📊 TABLE STATISTICS for {table_name}")
        print("=" * 70)
        
        stats = {}
        
        try:
            row_count = self.spark.sql(
                f"SELECT COUNT(*) FROM {table_name}"
            ).collect()[0][0]
            
            stats["row_count"] = row_count
            print(f"  📝 Total rows: {row_count:,}")
            
            if row_count > 0:
                bytes_per_row = 100  # Estimate
                stats["bytes_per_row"] = bytes_per_row
                print(f"  ⚡ Est. bytes per row: {bytes_per_row}")
            
            try:
                partition_stats = self.spark.sql(f"""
                    SELECT 
                        year,
                        COUNT(*) as row_count,
                        COUNT(DISTINCT month) as month_count
                    FROM {table_name}
                    GROUP BY year
                    ORDER BY year DESC
                """).collect()
                
                stats["partition_distribution"] = []
                
                print(f"\n  🗂️  Partition Distribution:")
                for row in partition_stats:
                    year = row[0]
                    count = row[1]
                    months = row[2]
                    
                    partition_info = {
                        "year": year,
                        "row_count": count,
                        "month_count": months
                    }
                    stats["partition_distribution"].append(partition_info)
                    
                    print(f"     Year {year}: {count:,} rows, {months} months")
                    
            except Exception as e:
                print(f"  ⚠️  Could not get partition stats: {str(e)[:50]}")
            
            stats["timestamp"] = datetime.now().isoformat()
            
        except Exception as e:
            print(f"  ❌ Error collecting stats: {str(e)[:100]}")
            stats["error"] = str(e)[:100]
        
        return stats
    
    def analyze_query_performance(self, table_name):
        """Run query suite and analyze performance"""
        print(f"\n⚡ QUERY PERFORMANCE ANALYSIS")
        print("=" * 70)
        
        queries = [
            {
                "name": "Full Table Scan",
                "sql": f"SELECT COUNT(*) FROM {table_name}",
                "category": "full_scan"
            },
            {
                "name": "Single Year Filter",
                "sql": f"SELECT COUNT(*) FROM {table_name} WHERE year = 2025",
                "category": "partition_filter"
            },
            {
                "name": "Year+Month Filter",
                "sql": f"SELECT COUNT(*) FROM {table_name} WHERE year = 2025 AND month = 6",
                "category": "multi_partition_filter"
            },
            {
                "name": "Category Filter",
                "sql": f"SELECT COUNT(*) FROM {table_name} WHERE category = 'Electronics'",
                "category": "column_filter"
            },
            {
                "name": "Aggregation",
                "sql": f"SELECT category, COUNT(*) FROM {table_name} GROUP BY category",
                "category": "aggregation"
            },
        ]
        
        query_results = []
        
        for query_spec in queries:
            start_time = time.time()
            
            try:
                result = self.spark.sql(query_spec["sql"])
                result.collect()
                
                elapsed = time.time() - start_time
                
                result_info = {
                    "name": query_spec["name"],
                    "category": query_spec["category"],
                    "time_seconds": elapsed,
                    "status": "SUCCESS"
                }
                
                query_results.append(result_info)
                
                if elapsed < 0.5:
                    perf = "🚀 FAST"
                elif elapsed < 2.0:
                    perf = "✅ GOOD"
                elif elapsed < 5.0:
                    perf = "⚠️  MODERATE"
                else:
                    perf = "🔴 SLOW"
                
                print(f"  {perf} {query_spec['name']}: {elapsed:.3f}s")
                
            except Exception as e:
                elapsed = time.time() - start_time
                
                result_info = {
                    "name": query_spec["name"],
                    "category": query_spec["category"],
                    "time_seconds": elapsed,
                    "status": "FAILED",
                    "error": str(e)[:100]
                }
                
                query_results.append(result_info)
                print(f"  ❌ {query_spec['name']}: ERROR")
        
        print(f"\n  📈 Performance Patterns:")
        
        full_scan_time = next(
            (q["time_seconds"] for q in query_results 
             if q["category"] == "full_scan"), None
        )
        partition_filter_time = next(
            (q["time_seconds"] for q in query_results 
             if q["category"] == "partition_filter"), None
        )
        
        if full_scan_time and partition_filter_time:
            speedup = full_scan_time / partition_filter_time if partition_filter_time > 0 else 0
            print(f"     Partition pruning speedup: {speedup:.1f}x")
        
        successful = [q for q in query_results if q["status"] == "SUCCESS"]
        if successful:
            avg_time = sum(q["time_seconds"] for q in successful) / len(successful)
            print(f"     Average query time: {avg_time:.3f}s")
        
        return query_results
    
    def identify_slow_queries(self, query_results, threshold_seconds=2.0):
        """Identify queries exceeding performance threshold"""
        print(f"\n🔍 SLOW QUERY ANALYSIS (threshold: {threshold_seconds}s)")
        print("=" * 70)
        
        slow_queries = [q for q in query_results 
                       if q["status"] == "SUCCESS" and q["time_seconds"] > threshold_seconds]
        
        if slow_queries:
            print(f"  Found {len(slow_queries)} slow queries:")
            for q in slow_queries:
                print(f"    ⚠️  {q['name']}: {q['time_seconds']:.3f}s")
        else:
            print(f"  ✅ No slow queries found")
        
        return {
            "threshold_seconds": threshold_seconds,
            "slow_query_count": len(slow_queries),
            "slow_queries": slow_queries
        }
    
    def generate_report(self, table_stats, query_results, slow_analysis):
        """Generate comprehensive monitoring report"""
        print(f"\n📋 MONITORING REPORT")
        print("=" * 70)
        
        successful = [q for q in query_results if q["status"] == "SUCCESS"]
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "table_statistics": table_stats,
            "query_performance": query_results,
            "slow_query_analysis": slow_analysis,
            "summary": {
                "total_rows": table_stats.get("row_count", 0),
                "avg_queries_perf": sum(q["time_seconds"] for q in successful) / len(successful) if successful else 0,
                "slow_queries": slow_analysis["slow_query_count"],
                "health": "GOOD" if slow_analysis["slow_query_count"] == 0 else "NEEDS_OPTIMIZATION"
            }
        }
        
        print(f"  📝 Total rows: {report['summary']['total_rows']:,}")
        print(f"  ⚡ Avg query time: {report['summary']['avg_queries_perf']:.3f}s")
        print(f"  🔴 Slow queries: {report['summary']['slow_queries']}")
        print(f"  🏥 Health: {report['summary']['health']}")
        
        return report
    
    def run(self):
        """Execute full monitoring workflow"""
        print("\n" + "="*70)
        print("📊 MONITORING & STATISTICS - ITERATION 3")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        table_stats = self.collect_table_statistics(table_name)
        query_results = self.analyze_query_performance(table_name)
        slow_analysis = self.identify_slow_queries(query_results, threshold_seconds=2.0)
        report = self.generate_report(table_stats, query_results, slow_analysis)
        
        output_file = "/tmp/monitoring_report.json"
        with open(output_file, "w") as f:
            json.dump(report, f, indent=2)
        
        print(f"\n✅ MONITORING TEST COMPLETO")
        print(f"📁 Report saved to: {output_file}")
        
        return report


if __name__ == "__main__":
    manager = MonitoringManager()
    manager.run()
