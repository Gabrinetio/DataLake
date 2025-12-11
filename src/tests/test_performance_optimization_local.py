#!/usr/bin/env python3

"""
🚀 Iteração 6 - FASE 1: Performance Testing (Local)
Script: test_performance_optimization_local.py
Data: 9 de dezembro de 2025

Testa performance Spark otimizado usando filesystem local
"""

import time
import json
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count, avg, sum as spark_sum

def create_spark_session():
    """Cria sessão Spark otimizada para teste local - SEM Iceberg"""
    return SparkSession.builder \
        .appName("PerformanceOptimizationTestLocal") \
        .getOrCreate()

def generate_test_data(spark, num_records=10000):
    """Gera dados de teste usando Parquet local"""
    print(f"📊 Gerando {num_records} registros de teste...")

    df = spark.range(num_records).selectExpr(
        "id",
        "date_format(date_add(current_date(), cast(rand() * 365 as int)), 'yyyy-MM-dd') as date",
        "round(rand() * 1000, 2) as value",
        "case when rand() > 0.5 then 'sales' else 'marketing' end as department",
        "concat('product_', cast(rand() * 100 as int)) as product",
        "concat('region_', cast(rand() * 10 as int)) as region"
    )

    # Salvar como Parquet local (não Iceberg para evitar problemas S3)
    df.write.mode("overwrite").parquet("/tmp/performance_test")
    print("✅ Dados salvos em /tmp/performance_test")

    # Ler de volta
    df_loaded = spark.read.parquet("/tmp/performance_test")
    return df_loaded

def run_performance_tests(spark):
    """Executa bateria de testes de performance"""
    results = {}

    print("\n🧪 EXECUTANDO TESTES DE PERFORMANCE")
    print("=" * 50)

    # Test 1: Simple Count
    print("📊 Test 1: Simple Count")
    start = time.time()
    count_result = spark.sql("SELECT COUNT(*) FROM parquet.`/tmp/performance_test`").collect()[0][0]
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
        FROM parquet.`/tmp/performance_test`
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
            FROM parquet.`/tmp/performance_test`
            GROUP BY department, region
        ) t1
        JOIN (
            SELECT department, AVG(value) as avg_value, COUNT(*) as cnt
            FROM parquet.`/tmp/performance_test`
            GROUP BY department
        ) t2 ON t1.department = t2.department
    """).collect()
    elapsed = time.time() - start
    results["complex_join"] = {
        "results": len(join_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {len(join_result)} resultados em {elapsed:.3f}s")

    # Test 4: Window Functions
    print("\n📊 Test 4: Window Functions")
    start = time.time()
    window_result = spark.sql("""
        SELECT department, value,
               ROW_NUMBER() OVER (PARTITION BY department ORDER BY value DESC) as rn,
               SUM(value) OVER (PARTITION BY department) as dept_total
        FROM parquet.`/tmp/performance_test`
        WHERE value > 500
    """).collect()
    elapsed = time.time() - start
    results["window_functions"] = {
        "filtered_results": len(window_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {len(window_result)} resultados em {elapsed:.3f}s")

    # Test 5: Multiple Aggregations
    print("\n📊 Test 5: Multiple Aggregations")
    start = time.time()
    multi_agg_result = spark.sql("""
        SELECT
            department,
            COUNT(*) as total_records,
            SUM(value) as total_value,
            AVG(value) as avg_value,
            MIN(value) as min_value,
            MAX(value) as max_value,
            STDDEV(value) as stddev_value
        FROM parquet.`/tmp/performance_test`
        GROUP BY department
        ORDER BY total_value DESC
    """).collect()
    elapsed = time.time() - start
    results["multi_aggregations"] = {
        "departments": len(multi_agg_result),
        "time_seconds": round(elapsed, 3)
    }
    print(f"   ✅ {len(multi_agg_result)} departamentos em {elapsed:.3f}s")

    return results

def main():
    print("🚀 PERFORMANCE OPTIMIZATION TEST - LOCAL")
    print("=" * 60)
    print("Data:", time.strftime("%Y-%m-%d %H:%M:%S"))
    print("Spark Version: 3.5.7")
    print("Storage: Local Parquet")
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
            "spark_config": "optimized_v1_local"
        }

        # Salvar resultados
        output_file = "/opt/datalake/results/performance_optimization_local_results.json"
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
            "Simple Count": (results["simple_count"]["time_seconds"], 1.0),
            "Group By": (results["group_by_agg"]["time_seconds"], 2.0),
            "Complex Join": (results["complex_join"]["time_seconds"], 3.0),
            "Window Functions": (results["window_functions"]["time_seconds"], 2.0),
            "Multi Aggregations": (results["multi_aggregations"]["time_seconds"], 2.0)
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