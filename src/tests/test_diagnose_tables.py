#!/usr/bin/env python3
"""
Diagnóstico de Tabelas no Catálogo Iceberg
Verifica que tabelas estão disponíveis e como acessá-las
"""

import sys
import json
import traceback
from datetime import datetime
from src.config import get_spark_s3_config

def diagnose_tables():
    """Diagnostica a disponibilidade de tabelas no cluster Spark"""
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "diagnosis": [],
        "errors": [],
        "recommendations": []
    }
    
    try:
        from pyspark.sql import SparkSession
        
        # Tentar criar SparkSession com Iceberg
        print("\n" + "="*70)
        print("🔍 DIAGNÓSTICO DE TABELAS ICEBERG")
        print("="*70 + "\n")
        
        print("1️⃣  Criando SparkSession COM extensões Iceberg...")
        try:
            spark_config = get_spark_s3_config()
            spark = SparkSession.builder \
                .appName("Diagnose_Tables_v1") \
                .master("local[2]") \
                .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
                .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
                .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
                .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
                .getOrCreate()
            
            print("   ✅ SparkSession com Iceberg criada com sucesso")
            results["diagnosis"].append({
                "step": "SparkSession with Iceberg extensions",
                "status": "SUCCESS"
            })
            
            # Listar catálogos
            print("\n2️⃣  Listando catálogos disponíveis...")
            try:
                catalogs = spark.sql("SHOW CATALOGS").collect()
                print(f"   📚 Catálogos encontrados: {len(catalogs)}")
                for catalog in catalogs:
                    print(f"      • {catalog[0]}")
                    results["diagnosis"].append({
                        "step": "SHOW CATALOGS",
                        "catalog": catalog[0]
                    })
            except Exception as e:
                print(f"   ⚠️  Erro ao listar catálogos: {e}")
                results["errors"].append(f"SHOW CATALOGS error: {str(e)}")
            
            # Listar esquemas no catálogo hadoop_prod
            print("\n3️⃣  Listando esquemas em hadoop_prod...")
            try:
                schemas = spark.sql("SHOW SCHEMAS IN hadoop_prod").collect()
                print(f"   📂 Esquemas encontrados: {len(schemas)}")
                for schema in schemas:
                    print(f"      • {schema[0]}")
            except Exception as e:
                print(f"   ⚠️  Erro ao listar esquemas: {e}")
                results["errors"].append(f"SHOW SCHEMAS error: {str(e)}")
            
            # Listar tabelas no default
            print("\n4️⃣  Listando tabelas em hadoop_prod.default...")
            try:
                tables = spark.sql("SHOW TABLES IN hadoop_prod.default").collect()
                print(f"   📋 Tabelas encontradas: {len(tables)}")
                for table in tables:
                    print(f"      • {table[0]}.{table[1]}")
                    results["diagnosis"].append({
                        "step": "SHOW TABLES",
                        "table": f"{table[0]}.{table[1]}"
                    })
            except Exception as e:
                print(f"   ⚠️  Erro ao listar tabelas: {e}")
                results["errors"].append(f"SHOW TABLES error: {str(e)}")
                
                # Tentar alternativa: listar arquivos no S3
                print("\n   ℹ️  Tentando alternativa: listar arquivos no S3...")
                try:
                    files = spark.sparkContext.binaryFiles("s3a://datalake/warehouse/default/vendas_small/").take(5)
                    print(f"   📁 Arquivos encontrados em S3: {len(files)}")
                    results["diagnosis"].append({
                        "step": "S3 files listing",
                        "files_found": len(files)
                    })
                except Exception as e2:
                    print(f"   ⚠️  Erro ao listar arquivos S3: {e2}")
            
            # Tentar usar tabela diretamente
            print("\n5️⃣  Tentando acessar vendas_small com diferentes qualificações...")
            
            table_names = [
                "hadoop_prod.default.vendas_small",
                "default.vendas_small",
                "vendas_small",
                "hadoop_prod.vendas_small"
            ]
            
            for table_name in table_names:
                try:
                    count = spark.sql(f"SELECT COUNT(*) FROM {table_name}").collect()[0][0]
                    print(f"   ✅ {table_name}: {count} registros")
                    results["diagnosis"].append({
                        "step": "Table access",
                        "table": table_name,
                        "status": "SUCCESS",
                        "row_count": count
                    })
                except Exception as e:
                    print(f"   ❌ {table_name}: ERRO")
                    results["diagnosis"].append({
                        "step": "Table access",
                        "table": table_name,
                        "status": "FAILED",
                        "error": str(e)[:100]
                    })
            
            spark.stop()
            
        except Exception as e:
            print(f"   ❌ Erro criando SparkSession com Iceberg: {e}")
            results["errors"].append(f"SparkSession creation error: {str(e)}")
            
            # Tentar criar SparkSession SEM Iceberg
            print("\n6️⃣  Tentando SparkSession SEM extensões Iceberg...")
            try:
                spark_config = get_spark_s3_config()
                spark = SparkSession.builder \
                    .appName("Diagnose_Tables_v2") \
                    .master("local[2]") \
                    .getOrCreate()
                
                print("   ✅ SparkSession sem Iceberg criada")
                
                # Tentar listar arquivo Parquet direto
                print("\n   Tentando ler Parquet de s3a://datalake/warehouse/default/vendas_small/...")
                try:
                    df = spark.read.parquet("s3a://datalake/warehouse/default/vendas_small/")
                    count = df.count()
                    print(f"   ✅ Leitura bem-sucedida: {count} registros")
                    print(f"      Schema: {df.schema}")
                    results["diagnosis"].append({
                        "step": "Direct Parquet read",
                        "status": "SUCCESS",
                        "row_count": count
                    })
                except Exception as e2:
                    print(f"   ❌ Erro lendo Parquet: {e2}")
                    results["errors"].append(f"Parquet read error: {str(e2)}")
                
                spark.stop()
                
            except Exception as e2:
                print(f"   ❌ Erro criando SparkSession sem Iceberg: {e2}")
                results["errors"].append(f"SparkSession without Iceberg error: {str(e2)}")
        
    except Exception as e:
        print(f"\n❌ ERRO GERAL: {e}")
        traceback.print_exc()
        results["errors"].append(f"General error: {str(e)}")
    
    # Gerar recomendações
    print("\n" + "="*70)
    print("💡 RECOMENDAÇÕES")
    print("="*70 + "\n")
    
    if any("TABLE_OR_VIEW_NOT_FOUND" in str(err) for err in results["errors"]):
        rec = "Tabela não encontrada. Pode ser que:\n  - A tabela não foi criada corretamente\n  - A tabela está em outro catálogo/schema\n  - Os dados estão em outro local no S3"
        print(f"   {rec}")
        results["recommendations"].append(rec)
    
    if any("Cannot find catalog plugin" in str(err) for err in results["errors"]):
        rec = "Catálogo Iceberg não configurado corretamente. Verificar:\n  - Iceberg JAR no classpath\n  - Configuração de spark.sql.catalog.hadoop_prod\n  - Versão compatível do Spark"
        print(f"   {rec}")
        results["recommendations"].append(rec)
    
    # Salvar resultados
    output_file = "/tmp/diagnose_tables_results.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\n✅ Resultados salvos em: {output_file}\n")
    
    return results

if __name__ == "__main__":
    diagnose_tables()
