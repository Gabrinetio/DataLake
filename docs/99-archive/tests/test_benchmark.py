from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, count, sum, avg, max, min
import time
import json
from datetime import datetime
from pathlib import Path
from src.config import get_spark_s3_config

class IcebergBenchmark:
    """Suite de benchmarks para tabelas Iceberg"""
    
    def __init__(self):
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("IcebergBenchmark") \
            .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
            .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.adaptive.enabled", "true") \
            .getOrCreate()
        
        self.results = []
    
    def benchmark_query(self, name, sql, iterations=3):
        """Executa uma query e mede tempo"""
        
        print(f"\n{'='*70}")
        print(f"Benchmark: {name}")
        print(f"{'='*70}")
        print(f"Query: {sql[:100]}...")
        
        times = []
        for i in range(iterations):
            print(f"  Iteração {i+1}/{iterations}...", end=" ", flush=True)
            
            start = time.time()
            result = self.spark.sql(sql)
            result.collect()  # Forçar execução
            elapsed = time.time() - start
            
            times.append(elapsed)
            print(f"{elapsed:.2f}s")
        
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        
        print(f"\nResultados:")
        print(f"  Média: {avg_time:.2f}s")
        print(f"  Mínimo: {min_time:.2f}s")
        print(f"  Máximo: {max_time:.2f}s")
        
        result_obj = {
            "name": name,
            "query": sql,
            "avg_time_seconds": avg_time,
            "min_time_seconds": min_time,
            "max_time_seconds": max_time,
            "iterations": iterations
        }
        
        self.results.append(result_obj)
        return result_obj
    
    def run_all_benchmarks(self):
        """Executa suite completa de benchmarks"""
        
        print("\n" + "="*70)
        print("SUITE DE BENCHMARKS - ICEBERG")
        print("="*70)
        print(f"Timestamp: {datetime.now().isoformat()}\n")
        
        # 1. Full Scan
        self.benchmark_query(
            "Full Scan - COUNT",
            "SELECT COUNT(*) FROM hadoop_prod.default.vendas_teste"
        )
        
        # 2. Partition Filter
        self.benchmark_query(
            "Partition Filter - Single Month",
            "SELECT COUNT(*) FROM hadoop_prod.default.vendas_teste WHERE year = 2023 AND month = 6"
        )
        
        # 3. Partition Filter - Multiple Months
        self.benchmark_query(
            "Partition Filter - Multiple Months",
            "SELECT COUNT(*) FROM hadoop_prod.default.vendas_teste WHERE year = 2023 AND month IN (1, 3, 6, 9)"
        )
        
        # 4. Column Filter
        self.benchmark_query(
            "Column Filter - Amount > 1000",
            "SELECT COUNT(*) FROM hadoop_prod.default.vendas_teste WHERE sale_amount > 1000"
        )
        
        # 5. Aggregation - Simple
        self.benchmark_query(
            "Aggregation - SUM by Category",
            "SELECT category, SUM(sale_amount) FROM hadoop_prod.default.vendas_teste GROUP BY category"
        )
        
        # 6. Aggregation - Complex
        self.benchmark_query(
            "Aggregation - Multiple Metrics",
            """
            SELECT 
                year, month, category,
                COUNT(*) as num_sales,
                SUM(sale_amount) as total_sales,
                AVG(sale_amount) as avg_sale,
                MIN(sale_amount) as min_sale,
                MAX(sale_amount) as max_sale
            FROM hadoop_prod.default.vendas_teste
            GROUP BY year, month, category
            """
        )
        
        # 7. Join
        self.benchmark_query(
            "Join - Vendas + Inventário",
            """
            SELECT COUNT(*)
            FROM hadoop_prod.default.vendas_teste v
            JOIN hadoop_prod.default.inventario i
            ON v.product_id = i.product_id
            """
        )
        
        # 8. Window Function
        self.benchmark_query(
            "Window Function - Running Total",
            """
            SELECT 
                transaction_id,
                sale_amount,
                SUM(sale_amount) OVER (ORDER BY transaction_id) as running_total
            FROM hadoop_prod.default.vendas_teste
            LIMIT 100000
            """
        )
        
        # 9. Subquery
        self.benchmark_query(
            "Subquery - Top Categories",
            """
            SELECT category, total_sales
            FROM (
                SELECT category, SUM(sale_amount) as total_sales
                FROM hadoop_prod.default.vendas_teste
                GROUP BY category
            )
            WHERE total_sales > 100000
            ORDER BY total_sales DESC
            """
        )
        
        # 10. Complex Filter
        self.benchmark_query(
            "Complex Filter - Multiple Conditions",
            """
            SELECT COUNT(*)
            FROM hadoop_prod.default.vendas_teste
            WHERE year = 2023
            AND month >= 6
            AND sale_amount > 500
            AND quantity > 5
            AND category IN ('Electronics', 'Clothing')
            """
        )
        
        self.print_summary()
    
    def print_summary(self):
        """Imprime resumo dos benchmarks"""
        
        print("\n" + "="*70)
        print("RESUMO DOS BENCHMARKS")
        print("="*70)
        
        print(f"\n{'Query':<40} {'Avg Time (s)':<15} {'Min/Max'}")
        print("-"*70)
        
        for r in self.results:
            name = r['name'][:38]
            avg = r['avg_time_seconds']
            min_max = f"{r['min_time_seconds']:.2f}/{r['max_time_seconds']:.2f}"
            print(f"{name:<40} {avg:<15.2f} {min_max}")
        
        # Estatísticas
        total_time = sum(r['avg_time_seconds'] for r in self.results)
        avg_query_time = total_time / len(self.results)
        
        print("-"*70)
        print(f"{'Total Execution Time':<40} {total_time:.2f}s")
        print(f"{'Average Query Time':<40} {avg_query_time:.2f}s")
        print(f"{'Number of Queries':<40} {len(self.results)}")
        
        # Table Statistics
        print("\n" + "="*70)
        print("ESTATÍSTICAS DAS TABELAS")
        print("="*70)
        
        self.spark.sql("""
        SELECT 
            'vendas_teste' as table_name,
            COUNT(*) as record_count,
            COUNT(DISTINCT year) as years,
            COUNT(DISTINCT month) as months,
            COUNT(DISTINCT day) as days,
            COUNT(DISTINCT category) as categories
        FROM hadoop_prod.default.vendas_teste
        UNION ALL
        SELECT
            'inventario',
            COUNT(*),
            1, 1, 1, 1
        FROM hadoop_prod.default.inventario
        UNION ALL
        SELECT
            'clientes',
            COUNT(*),
            1, 1, 1, 1
        FROM hadoop_prod.default.clientes
        """).show(truncate=False)
        
        # Salvar resultados
        self.save_results()
    
    def save_results(self):
        """Salva resultados em arquivo JSON"""
        
        output = {
            "timestamp": datetime.now().isoformat(),
            "benchmarks": self.results,
            "summary": {
                "total_queries": len(self.results),
                "total_time_seconds": sum(r['avg_time_seconds'] for r in self.results),
                "average_query_time_seconds": sum(r['avg_time_seconds'] for r in self.results) / len(self.results)
            }
        }
        
        output_file = Path("benchmark_results.json")
        with open(output_file, 'w') as f:
            json.dump(output, f, indent=2)
        
        print(f"\n✓ Resultados salvos em: {output_file}")


if __name__ == "__main__":
    benchmark = IcebergBenchmark()
    benchmark.run_all_benchmarks()
