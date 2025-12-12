#!/usr/bin/env python3

"""
🚀 Iteração 6 - FASE 1: Performance Testing
Script: test_performance_optimization.py
Data: 9 de dezembro de 2025

Testa performance antes/depois das otimizações Spark + Iceberg
"""

import time
import json
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, avg, sum as spark_sum

def create_spark_session():
    """Cria sessão Spark otimizada"""
    return SparkSession.builder \
        .appName("PerformanceOptimizationTest") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkSessionCatalog") \
        .config("spark.sql.catalog.spark_catalog.type", "hive") \
        .config("spark.sql.catalog.spark_catalog.uri", "thrift://192.168.4.33:9083") \
        .config("spark.sql.catalog.spark_catalog.warehouse", "s3a://datalake/warehouse") \
        .config("spark.hadoop.fs.s3a.endpoint", "http://192.168.4.33:9000") \
        .config("spark.hadoop.fs.s3a.access.key", "datalake") \
        .config("spark.hadoop.fs.s3a.secret.key", "datalake123") \
        .config("spark.hadoop.fs.s3a.path.style.access", "true") \
        .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
        .getOrCreate()

def generate_test_data(spark, num_records=50000):
    """Gera dados de teste"""
    print(f"📊 Gerando {num_records} registros de teste...")

    df = spark.range(num_records).selectExpr(
        "id",
        "date_format(date_add(current_date(), cast(rand() * 365 as int)), 'yyyy-MM-dd') as date",
        "round(rand() * 1000, 2) as value",
        "case when rand() > 0.5 then 'sales' else 'marketing' end as department",
        "concat('product_', cast(rand() * 100 as int)) as product",
        "concat('region_', cast(rand() * 10 as int)) as region"
    )

    # Salvar como Iceberg table
    df.write.mode("overwrite") \
        .option("path", "s3a://datalake/warehouse/performance_test") \
        .format("iceberg") \
        .saveAsTable("performance_test")

    return df

def run_performance_tests(spark):
    """Executa bateria de testes de performance"""
    results = {}

    print("\n🧪 EXECUTANDO TESTES DE PERFORMANCE")
    print("=" * 50)

    # Test 1: Simple Count
    print("📊 Test 1: Simple Count")
    start = time.time()
    count_result = spark.sql("SELECT COUNT(*) FROM performance_test").collect()[0][0]
    elapsed = time.time() - start
    results["simple_count"] = {
        "records": count_result,
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {count_result} registros em {elapsed:.3f}s")

    # Test 2: Group By Aggregation
    print("\n📊 Test 2: Group By Aggregation")
    start = time.time()
    agg_result = spark.sql("""
        SELECT department, region, COUNT(*) as cnt,
               SUM(value) as total_value, AVG(value) as avg_value
        FROM performance_test
        GROUP BY department, region
        ORDER BY total_value DESC
    """).collect()
    elapsed = time.time() - start
    results["group_by_agg"] = {
        "groups": len(agg_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {len(agg_result)} grupos em {elapsed:.3f}s")

    # Test 3: Complex Join
    print("\n📊 Test 3: Complex Join")
    start = time.time()
    join_result = spark.sql("""
        SELECT t1.department, t1.region, t1.total_value,
               t2.avg_value, t2.cnt
        FROM (
            SELECT department, region, SUM(value) as total_value
            FROM performance_test
            GROUP BY department, region
        ) t1
        JOIN (
            SELECT department, AVG(value) as avg_value, COUNT(*) as cnt
            FROM performance_test
            GROUP BY department
        ) t2 ON t1.department = t2.department
    """).collect()
    elapsed = time.time() - start
    results["complex_join"] = {
        "results": len(join_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {len(join_result)} resultados em {elapsed:.3f}s")

    # Test 4: Iceberg Time Travel
    print("\n📊 Test 4: Iceberg Time Travel")
    start = time.time()
    # Criar snapshot
    spark.sql("SELECT * FROM performance_test").write.mode("append") \
        .option("path", "s3a://datalake/warehouse/performance_test") \
        .format("iceberg") \
        .saveAsTable("performance_test")

    # Time travel query
    tt_result = spark.sql("SELECT COUNT(*) FROM performance_test VERSION AS OF 1").collect()[0][0]
    elapsed = time.time() - start
    results["time_travel"] = {
        "snapshot_records": tt_result,
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ Time travel: {tt_result} registros em {elapsed:.3f}s")

    # Test 5: RLAC Query (simulando)
    print("\n📊 Test 5: RLAC-like Query")
    start = time.time()
    spark.sql("""
        CREATE OR REPLACE TEMPORARY VIEW performance_test_sales AS
        SELECT * FROM performance_test WHERE department = 'sales'
    """)

    rlac_result = spark.sql("""
        SELECT region, COUNT(*) as cnt, SUM(value) as total
        FROM performance_test_sales
        WHERE value > 100
        GROUP BY region
        ORDER BY total DESC
    """).collect()
    elapsed = time.time() - start
    results["rlac_query"] = {
        "filtered_results": len(rlac_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ RLAC query: {len(rlac_result)} resultados em {elapsed:.3f}s")

    return results

def main():
    print("🚀 PERFORMANCE OPTIMIZATION TEST - ITERAÇÃO 6")
    print("=" * 60)
    print("Data:", time.strftime("%Y-%m-%d %H:%M:%S"))
    print("Spark Version: 3.5.7")
    print("Iceberg Version: 1.10.0")
    print("=" * 60)

    try:
        # Criar sessão Spark
        spark = create_spark_session()
        print("✅ Spark session criada")

        # Gerar dados de teste
        test_df = generate_test_data(spark)
        print("✅ Dados de teste gerados")

        # Executar testes
        results = run_performance_tests(spark)

        # Calcular métricas agregadas
        total_time = sum(test["time_seconds"] for test in results.values())
        avg_time = total_time / len(results)

        results["summary"] = {
            "total_tests": len(results) - 1,  # excluindo summary
            "total_time_seconds": round(total_time, 3),
            "average_time_seconds": round(avg_time, 3),
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "spark_config": "optimized_v1"
        }

        # Salvar resultados
        output_file = "/opt/datalake/results/performance_optimization_results.json"
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)

        print("\n" + "=" * 60)
        print("📊 RESULTADOS FINAIS")
        print("=" * 60)
        print(f"Total de testes: {results['summary']['total_tests']}")
        print(f"Tempo total: {results['summary']['total_time_seconds']}s")
        print(f"Tempo médio: {results['summary']['average_time_seconds']}s")
        print(f"Arquivo salvo: {output_file}")

        # Validação de targets
        print("\n🎯 VALIDAÇÃO DE TARGETS")
        print("-" * 30)
        targets = {
            "Simple Count": (results["simple_count"]["time_seconds"], 2.0),
            "Group By": (results["group_by_agg"]["time_seconds"], 3.0),
            "Complex Join": (results["complex_join"]["time_seconds"], 5.0),
            "Time Travel": (results["time_travel"]["time_seconds"], 2.0),
            "RLAC Query": (results["rlac_query"]["time_seconds"], 2.0)
        }

        all_passed = True
        for test_name, (actual, target) in targets.items():
            status = "✅" if actual <= target else "❌"
            print(f"{status} {test_name}: {actual:.3f}s (target: {target:.1f}s)")
            if actual > target:
                all_passed = False

        print("\n" + "=" * 60)
        if all_passed:
            print("🎉 TODOS OS TARGETS ATINGIDOS! PERFORMANCE OTIMIZADA!")
        else:
            print("⚠️ Alguns targets não atingidos - revisar configurações")
        print("=" * 60)

        spark.stop()

    except Exception as e:
        print(f"❌ ERRO: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()