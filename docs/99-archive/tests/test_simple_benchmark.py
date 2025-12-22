from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, rand, when, lit, concat, year, month, dayofmonth
import json
import time
from decimal import Decimal
from src.config import get_spark_s3_config

class SimplifiedBenchmark:
    """Testes de performance com queries variadas"""
    
    def __init__(self):
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("IcebergBenchmark") \
            .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
            .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.parquet.compression.codec", "snappy") \
            .getOrCreate()
        
        self.results = []
    
    def run_query(self, query_name, sql_query):
        """Executa query e mede tempo"""
        
        print(f"\n⏱️  Executando: {query_name}")
        
        start = time.time()
        result = self.spark.sql(sql_query)
        count = result.count()
        elapsed = time.time() - start
        
        print(f"   Resultado: {count:,} linhas em {elapsed:.2f}s")
        
        self.results.append({
            "query": query_name,
            "execution_time_seconds": float(f"{elapsed:.3f}"),
            "rows_returned": count
        })
    
    def benchmark(self):
        """Executa suite de benchmarks"""
        
        print("\n" + "="*60)
        print("BENCHMARK - ICEBERG COM 50K REGISTROS")
        print("="*60)
        
        # Q1: Full Scan
        self.run_query(
            "Q1: Full Scan",
            "SELECT COUNT(*) FROM hadoop_prod.default.vendas_small"
        )
        
        # Q2: Filter Partition
        self.run_query(
            "Q2: Filter by Partition (month=6)",
            """
            SELECT COUNT(*) FROM hadoop_prod.default.vendas_small
            WHERE month = 6
            """
        )
        
        # Q3: Filter Column
        self.run_query(
            "Q3: Filter by sale_amount > 500",
            """
            SELECT COUNT(*) FROM hadoop_prod.default.vendas_small
            WHERE sale_amount > 500
            """
        )
        
        # Q4: Aggregation
        self.run_query(
            "Q4: Aggregation by category",
            """
            SELECT category, COUNT(*) as num_sales, SUM(sale_amount) as total
            FROM hadoop_prod.default.vendas_small
            GROUP BY category
            """
        )
        
        # Q5: Multi-filter
        self.run_query(
            "Q5: Multiple filters",
            """
            SELECT COUNT(*) FROM hadoop_prod.default.vendas_small
            WHERE month IN (1, 6, 12) AND sale_amount > 250 AND quantity > 5
            """
        )
        
        # Q6: Date range
        self.run_query(
            "Q6: Date range filter",
            """
            SELECT COUNT(*) FROM hadoop_prod.default.vendas_small
            WHERE sale_date BETWEEN '2023-06-01' AND '2023-08-31'
            """
        )
        
        # Q7: Top products
        self.run_query(
            "Q7: Top 10 products by sales",
            """
            SELECT product_id, SUM(sale_amount) as total
            FROM hadoop_prod.default.vendas_small
            GROUP BY product_id
            ORDER BY total DESC
            LIMIT 10
            """
        )
        
        # Q8: Distribution
        self.run_query(
            "Q8: Sales distribution",
            """
            SELECT 
                CASE 
                    WHEN sale_amount < 250 THEN 'Low'
                    WHEN sale_amount < 500 THEN 'Medium'
                    WHEN sale_amount < 750 THEN 'High'
                    ELSE 'Very High'
                END as range,
                COUNT(*) as count
            FROM hadoop_prod.default.vendas_small
            GROUP BY range
            ORDER BY range
            """
        )
        
        # Q9: Monthly summary
        self.run_query(
            "Q9: Monthly aggregation",
            """
            SELECT year, month, COUNT(*) as num_sales, ROUND(AVG(sale_amount), 2) as avg_sale
            FROM hadoop_prod.default.vendas_small
            GROUP BY year, month
            ORDER BY year, month
            """
        )
        
        # Q10: Complex join-like query
        self.run_query(
            "Q10: Complex aggregation",
            """
            SELECT 
                category,
                product_id,
                COUNT(*) as transactions,
                ROUND(SUM(sale_amount), 2) as total_sales,
                ROUND(AVG(quantity), 1) as avg_qty
            FROM hadoop_prod.default.vendas_small
            WHERE sale_amount > 300
            GROUP BY category, product_id
            HAVING COUNT(*) > 5
            ORDER BY total_sales DESC
            LIMIT 20
            """
        )
        
        print("\n" + "="*60)
        print("RESULTADOS")
        print("="*60)
        
        total_time = sum(r["execution_time_seconds"] for r in self.results)
        avg_time = total_time / len(self.results)
        
        for r in self.results:
            print(f"{r['query']:40} {r['execution_time_seconds']:8.3f}s  ({r['rows_returned']:,} rows)")
        
        print("\n" + "-"*60)
        print(f"Total time: {total_time:.3f}s")
        print(f"Average time: {avg_time:.3f}s")
        print("="*60)
        
        # Salvar resultados
        with open("/tmp/benchmark_results.json", "w") as f:
            json.dump({
                "table": "vendas_small",
                "total_records": 50000,
                "timestamp": str(time.time()),
                "queries": self.results,
                "summary": {
                    "total_time_seconds": float(f"{total_time:.3f}"),
                    "average_time_seconds": float(f"{avg_time:.3f}"),
                    "num_queries": len(self.results)
                }
            }, f, indent=2)
        
        print(f"\n✅ Resultados salvos em /tmp/benchmark_results.json")
        
        self.spark.stop()


if __name__ == "__main__":
    benchmark = SimplifiedBenchmark()
    benchmark.benchmark()
