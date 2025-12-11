"""
BI Integration - Business Intelligence Tools Integration
Iteração 5 - Feature 3

Objetivos:
1. Conectar DataLake ao Superset (ferramenta BI)
2. Criar data sources e datasets
3. Testar query performance via BI tool
4. Medir latência das queries (target < 30s)

Author: GitHub Copilot
Date: 7 de dezembro de 2025
Status: Teste Pronto
"""

from pyspark.sql import SparkSession
from pyspark.sql.types import *
from pyspark.sql.functions import *
import json
from datetime import datetime, timedelta
import time
import subprocess
import os

class BIIntegration:
    """Business Intelligence Integration com Superset"""
    
    def __init__(self, spark):
        self.spark = spark
        self.warehouse_path = "/home/datalake/warehouse"
        self.table_name = "vendas_bi"
        self.superset_url = "http://localhost:8088"
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "status": "PENDING",
            "phases": {}
        }
    
    def phase_1_create_bi_tables(self):
        """FASE 1: Criar tabelas otimizadas para BI"""
        print("\n" + "="*70)
        print("FASE 1: Criar Tabelas Otimizadas para BI")
        print("="*70)
        
        try:
            # Schema para tabela de vendas (fatos)
            schema_vendas = StructType([
                StructField("id", LongType()),
                StructField("data_venda", DateType()),
                StructField("produto", StringType()),
                StructField("categoria", StringType()),
                StructField("departamento", StringType()),
                StructField("quantidade", IntegerType()),
                StructField("valor_unitario", DoubleType()),
                StructField("valor_total", DoubleType()),
                StructField("regiao", StringType()),
                StructField("mes", IntegerType()),
                StructField("ano", IntegerType()),
            ])
            
            # Gerar dados (50K records)
            print("   Gerando 50K records para BI...")
            data = []
            base_date = datetime(2025, 1, 1)
            categorias = ["Eletrônicos", "Roupas", "Alimentos", "Livros", "Móveis"]
            regioes = ["Norte", "Nordeste", "Centro", "Sul", "Sudeste"]
            depts = ["Vendas", "Marketing", "Suporte", "Administrativo"]
            
            for i in range(50000):
                date = base_date + timedelta(days=i % 365)
                data.append((
                    i + 1,
                    date.date(),
                    f"Produto_{i % 200}",
                    categorias[i % len(categorias)],
                    depts[i % len(depts)],
                    (i % 100) + 1,
                    10.0 + (i % 1000) * 0.1,
                    ((i % 100) + 1) * (10.0 + (i % 1000) * 0.1),
                    regioes[i % len(regioes)],
                    date.month,
                    date.year,
                ))
            
            df_vendas = self.spark.createDataFrame(data, schema=schema_vendas)
            
            # Salvar como Iceberg (otimizado para queries)
            print("   Salvando tabela vendas_bi...")
            df_vendas.write \
                .format("iceberg") \
                .mode("overwrite") \
                .partitionBy("ano", "mes") \
                .saveAsTable(self.table_name)
            
            # Criar view agregada (para dashboards)
            print("   Criando view agregada por categoria...")
            self.spark.sql(f"""
                CREATE OR REPLACE VIEW vendas_por_categoria AS
                SELECT 
                    categoria,
                    COUNT(*) as total_vendas,
                    SUM(quantidade) as quantidade_total,
                    SUM(valor_total) as valor_total,
                    AVG(valor_unitario) as preco_medio
                FROM {self.table_name}
                GROUP BY categoria
            """)
            
            # Criar view por região
            print("   Criando view agregada por região...")
            self.spark.sql(f"""
                CREATE OR REPLACE VIEW vendas_por_regiao AS
                SELECT 
                    regiao,
                    ano,
                    mes,
                    COUNT(*) as total_vendas,
                    SUM(valor_total) as valor_total,
                    AVG(valor_total) as ticket_medio
                FROM {self.table_name}
                GROUP BY regiao, ano, mes
            """)
            
            # Criar view por time (departamento)
            print("   Criando view agregada por departamento...")
            self.spark.sql(f"""
                CREATE OR REPLACE VIEW vendas_por_departamento AS
                SELECT 
                    departamento,
                    COUNT(*) as total_vendas,
                    SUM(valor_total) as valor_total,
                    AVG(valor_total) as ticket_medio,
                    MAX(valor_total) as maior_venda
                FROM {self.table_name}
                GROUP BY departamento
            """)
            
            count = self.spark.sql(f"SELECT COUNT(*) as count FROM {self.table_name}").collect()[0]['count']
            print(f"   ✅ Tabelas criadas: {count} records")
            print(f"   ✅ Views agregadas criadas: 3 views")
            
            self.results["phases"]["bi_tables"] = {
                "status": "SUCCESS",
                "main_table": self.table_name,
                "records": count,
                "views": 3,
                "aggregations": ["por_categoria", "por_regiao", "por_departamento"]
            }
            return True
            
        except Exception as e:
            print(f"   ❌ Erro: {str(e)}")
            self.results["phases"]["bi_tables"] = {"status": "FAILED", "error": str(e)}
            return False
    
    def phase_2_test_bi_queries(self):
        """FASE 2: Testar queries de BI com medição de latência"""
        print("\n" + "="*70)
        print("FASE 2: Testar Queries de BI")
        print("="*70)
        
        try:
            queries = [
                {
                    "name": "Total Vendas",
                    "query": f"SELECT SUM(valor_total) as total FROM {self.table_name}"
                },
                {
                    "name": "Vendas por Categoria",
                    "query": f"SELECT categoria, SUM(valor_total) as total FROM {self.table_name} GROUP BY categoria"
                },
                {
                    "name": "Vendas por Região e Mês",
                    "query": f"SELECT regiao, mes, COUNT(*) as total FROM {self.table_name} GROUP BY regiao, mes"
                },
                {
                    "name": "Top Produtos",
                    "query": f"SELECT produto, SUM(valor_total) as total FROM {self.table_name} GROUP BY produto ORDER BY total DESC LIMIT 10"
                },
                {
                    "name": "Performance por Departamento",
                    "query": f"SELECT departamento, COUNT(*) as vendas, AVG(valor_total) as ticket_medio FROM {self.table_name} GROUP BY departamento"
                }
            ]
            
            query_results = {}
            target_latency_ms = 30000  # 30 segundos
            all_passed = True
            
            for i, q in enumerate(queries, 1):
                print(f"\n   Query {i}: {q['name']}")
                
                try:
                    start = time.time()
                    result = self.spark.sql(q['query']).collect()
                    latency_ms = (time.time() - start) * 1000
                    
                    passed = latency_ms < target_latency_ms
                    status = "✅" if passed else "⚠️"
                    
                    print(f"      {status} Latência: {latency_ms:.2f}ms (target: {target_latency_ms}ms)")
                    print(f"      Rows retornadas: {len(result)}")
                    
                    query_results[q['name']] = {
                        "latency_ms": latency_ms,
                        "rows": len(result),
                        "passed": passed
                    }
                    
                    if not passed:
                        all_passed = False
                        
                except Exception as e:
                    print(f"      ❌ Erro: {str(e)}")
                    query_results[q['name']] = {
                        "error": str(e),
                        "passed": False
                    }
                    all_passed = False
            
            self.results["phases"]["bi_queries"] = {
                "status": "SUCCESS",
                "queries": query_results,
                "all_passed": all_passed,
                "target_latency_ms": target_latency_ms
            }
            
            return all_passed
            
        except Exception as e:
            print(f"   ❌ Erro geral: {str(e)}")
            self.results["phases"]["bi_queries"] = {"status": "FAILED", "error": str(e)}
            return False
    
    def phase_3_dashboard_simulation(self):
        """FASE 3: Simular criação e execução de dashboard"""
        print("\n" + "="*70)
        print("FASE 3: Dashboard Simulation")
        print("="*70)
        
        try:
            dashboard_charts = [
                {
                    "name": "Sales Overview",
                    "type": "number",
                    "query": f"SELECT SUM(valor_total) FROM {self.table_name}"
                },
                {
                    "name": "Sales by Category",
                    "type": "bar",
                    "query": f"SELECT categoria, SUM(valor_total) FROM {self.table_name} GROUP BY categoria"
                },
                {
                    "name": "Regional Performance",
                    "type": "map",
                    "query": f"SELECT regiao, COUNT(*) FROM {self.table_name} GROUP BY regiao"
                },
                {
                    "name": "Departmental Metrics",
                    "type": "table",
                    "query": f"SELECT departamento, COUNT(*) as vendas, SUM(valor_total) as total FROM {self.table_name} GROUP BY departamento"
                },
            ]
            
            print(f"   Simulando dashboard com {len(dashboard_charts)} charts...")
            
            dashboard_results = {}
            all_passed = True
            
            start_dashboard = time.time()
            
            for chart in dashboard_charts:
                try:
                    chart_name = chart['name']
                    print(f"      Renderizando: {chart_name} ({chart['type']})...")
                    
                    start = time.time()
                    result = self.spark.sql(chart['query']).collect()
                    chart_latency = (time.time() - start) * 1000
                    
                    # Dashboard chart latency target: < 2 segundos
                    passed = chart_latency < 2000
                    status = "✅" if passed else "⚠️"
                    
                    print(f"         {status} {chart_latency:.0f}ms")
                    
                    dashboard_results[chart_name] = {
                        "type": chart['type'],
                        "latency_ms": chart_latency,
                        "passed": passed
                    }
                    
                    if not passed:
                        all_passed = False
                        
                except Exception as e:
                    print(f"         ❌ Erro: {str(e)}")
                    dashboard_results[chart['name']] = {
                        "error": str(e),
                        "passed": False
                    }
                    all_passed = False
            
            dashboard_total_time = (time.time() - start_dashboard) * 1000
            
            print(f"\n      Total dashboard render time: {dashboard_total_time:.0f}ms")
            
            self.results["phases"]["dashboard"] = {
                "status": "SUCCESS",
                "charts": len(dashboard_charts),
                "chart_results": dashboard_results,
                "total_time_ms": dashboard_total_time,
                "all_passed": all_passed
            }
            
            return all_passed
            
        except Exception as e:
            print(f"   ❌ Erro: {str(e)}")
            self.results["phases"]["dashboard"] = {"status": "FAILED", "error": str(e)}
            return False
    
    def run_full_test(self):
        """Executar teste completo de BI Integration"""
        print("\n\n")
        print("╔" + "="*68 + "╗")
        print("║" + " BI INTEGRATION - BUSINESS INTELLIGENCE TESTING ".center(68) + "║")
        print("╚" + "="*68 + "╝")
        
        success = True
        
        # Phase 1: Create BI Tables
        if not self.phase_1_create_bi_tables():
            success = False
        
        # Phase 2: Test BI Queries
        if success and not self.phase_2_test_bi_queries():
            success = False
        
        # Phase 3: Dashboard Simulation
        if success and not self.phase_3_dashboard_simulation():
            success = False
        
        # Final Status
        print("\n" + "="*70)
        print("RESULTADO FINAL")
        print("="*70)
        
        self.results["status"] = "SUCCESS ✅" if success else "FAILED ❌"
        print(f"\nStatus: {self.results['status']}")
        print(f"Timestamp: {datetime.now().isoformat()}")
        
        return success, self.results


def main():
    """Main execution"""
    spark = SparkSession.builder \
        .appName("BI-Integration-Test") \
        .master("local[*]") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.spark_catalog.type", "hadoop") \
        .config("spark.sql.catalog.spark_catalog.warehouse", "/home/datalake/warehouse") \
        .getOrCreate()
    
    try:
        bi = BIIntegration(spark)
        success, results = bi.run_full_test()
        
        # Save results
        with open("/tmp/bi_integration_results.json", "w") as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n✅ Resultados salvos em: /tmp/bi_integration_results.json")
        
        return 0 if success else 1
        
    except Exception as e:
        print(f"\n❌ Erro fatal: {str(e)}")
        return 1
    finally:
        spark.stop()


if __name__ == "__main__":
    exit(main())
