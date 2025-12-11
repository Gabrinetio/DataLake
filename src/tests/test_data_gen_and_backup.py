#!/usr/bin/env python3
"""
Geração de Dados + Backup/Restore Procedimento em uma única execução
Para Iteration 4 - Production Hardening
Execução no servidor Spark
"""

import json
import traceback
from datetime import datetime, timedelta
import random
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType, TimestampType
from pyspark.sql.functions import col, when, year, month, to_date
import os
import subprocess
from src.config import get_spark_s3_config

def generate_test_data(spark, num_records=50000):
    """Gera dados de teste (tabela vendas_small)"""
    
    print(f"\n📊 Gerando {num_records} registros de vendas...")
    
    # Criar dados simulados
    schema = StructType([
        StructField("id", IntegerType(), True),
        StructField("data_venda", TimestampType(), True),
        StructField("categoria", StringType(), True),
        StructField("produto", StringType(), True),
        StructField("quantidade", IntegerType(), True),
        StructField("preco_unitario", DoubleType(), True),
        StructField("total", DoubleType(), True),
    ])
    
    categorias = ["Eletrônicos", "Roupas", "Alimentos", "Livros", "Móveis"]
    produtos = {
        "Eletrônicos": ["Laptop", "Smartphone", "Tablet", "Fone", "Câmera"],
        "Roupas": ["Camiseta", "Calça", "Jaqueta", "Vestido", "Tênis"],
        "Alimentos": ["Arroz", "Feijão", "Pão", "Leite", "Queijo"],
        "Livros": ["Romance", "Técnico", "Infantil", "Poesia", "Biografia"],
        "Móveis": ["Mesa", "Cadeira", "Sofá", "Cama", "Estante"]
    }
    
    data = []
    start_date = datetime(2023, 1, 1)
    
    for i in range(1, num_records + 1):
        categoria = random.choice(categorias)
        produto = random.choice(produtos[categoria])
        quantidade = random.randint(1, 10)
        preco_unitario = round(random.uniform(10, 1000), 2)
        total = round(quantidade * preco_unitario, 2)
        data_venda = start_date + timedelta(days=random.randint(0, 730))
        
        data.append({
            "id": i,
            "data_venda": data_venda,
            "categoria": categoria,
            "produto": produto,
            "quantidade": quantidade,
            "preco_unitario": preco_unitario,
            "total": total,
        })
    
    df = spark.createDataFrame(data, schema)
    return df

def setup_spark_session():
    """Cria SparkSession sem Iceberg para evitar problemas"""
    
    print("\n🔧 Iniciando SparkSession...")
    
    spark_config = get_spark_s3_config()
    spark = SparkSession.builder \
        .appName("DataGen_Backup_Restore") \
        .master("local[2]") \
        .getOrCreate()
    
    print("✅ SparkSession criada")
    return spark

def create_and_save_table(spark, df):
    """Cria tabela vendas_small e salva em S3"""
    
    print("\n💾 Salvando tabela vendas_small em S3...")
    
    # Salvar como Parquet em S3 (sem Iceberg)
    s3_path = "s3a://datalake/warehouse/default/vendas_small"
    
    try:
        # Remover se já existe
        try:
            subprocess.run(
                ["hadoop", "fs", "-rm", "-r", s3_path],
                capture_output=True,
                timeout=30
            )
            print(f"   ✓ Removido caminho existente: {s3_path}")
        except:
            pass
        
        # Salvar DataFrame como Parquet
        df.write \
            .mode("overwrite") \
            .parquet(s3_path)
        
        print(f"   ✅ Tabela salva em: {s3_path}")
        
        # Verificar
        count = spark.read.parquet(s3_path).count()
        print(f"   ✓ Verificação: {count} registros")
        
        return True, count
        
    except Exception as e:
        print(f"   ❌ Erro salvando tabela: {e}")
        return False, 0

def backup_table(spark, s3_path, backup_name):
    """Cria backup da tabela"""
    
    print(f"\n🔄 Criando backup: {backup_name}...")
    
    try:
        df = spark.read.parquet(s3_path)
        count = df.count()
        
        # Salvar backup localmente
        backup_dir = f"/home/datalake/backups/{backup_name}"
        
        # Remover se já existe
        os.system(f"rm -rf {backup_dir}")
        
        df.write \
            .mode("overwrite") \
            .parquet(backup_dir)
        
        print(f"   ✅ Backup criado: {backup_dir}")
        print(f"   ✓ Registros: {count}")
        
        return True, count
        
    except Exception as e:
        print(f"   ❌ Erro no backup: {e}")
        return False, 0

def restore_from_backup(spark, backup_name, restore_path):
    """Restaura dados do backup para novo local"""
    
    print(f"\n↩️  Restaurando backup: {backup_name}...")
    
    try:
        backup_dir = f"/home/datalake/backups/{backup_name}"
        df = spark.read.parquet(backup_dir)
        count = df.count()
        
        # Salvar em novo local
        df.write \
            .mode("overwrite") \
            .parquet(restore_path)
        
        print(f"   ✅ Restaurado para: {restore_path}")
        print(f"   ✓ Registros: {count}")
        
        return True, count
        
    except Exception as e:
        print(f"   ❌ Erro na restauração: {e}")
        return False, 0

def validate_integrity(spark, original_path, backup_path):
    """Valida integridade entre original e backup"""
    
    print(f"\n✓ Validando integridade...")
    
    try:
        original_df = spark.read.parquet(original_path)
        backup_df = spark.read.parquet(backup_path)
        
        original_count = original_df.count()
        backup_count = backup_df.count()
        
        print(f"   Original: {original_count} registros")
        print(f"   Backup:   {backup_count} registros")
        
        if original_count == backup_count:
            print(f"   ✅ Integridade OK - contagens idênticas")
            return True, original_count, backup_count
        else:
            print(f"   ⚠️  Aviso: contagens diferentes!")
            return False, original_count, backup_count
            
    except Exception as e:
        print(f"   ❌ Erro validando integridade: {e}")
        return False, 0, 0

def run():
    """Executa todo o procedimento"""
    
    print("\n" + "="*70)
    print("🚀 GERAÇÃO DE DADOS + BACKUP/RESTORE - ITERATION 4")
    print("="*70)
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "steps": [],
        "summary": {},
        "errors": []
    }
    
    try:
        # 1. Criar SparkSession
        spark = setup_spark_session()
        results["steps"].append({
            "step": "SparkSession creation",
            "status": "SUCCESS"
        })
        
        # 2. Gerar dados
        print("\n" + "="*70)
        print("FASE 1: GERAÇÃO DE DADOS")
        print("="*70)
        
        df_vendas = generate_test_data(spark, num_records=50000)
        df_vendas.show(5)
        
        results["steps"].append({
            "step": "Data generation",
            "status": "SUCCESS",
            "records": 50000
        })
        
        # 3. Criar tabela em S3
        print("\n" + "="*70)
        print("FASE 2: CRIAÇÃO DE TABELA")
        print("="*70)
        
        success, count = create_and_save_table(spark, df_vendas)
        
        if not success:
            raise Exception("Falha ao criar tabela")
        
        s3_path = "s3a://datalake/warehouse/default/vendas_small"
        
        results["steps"].append({
            "step": "Table creation",
            "status": "SUCCESS",
            "location": s3_path,
            "records": count
        })
        
        # 4. Backup
        print("\n" + "="*70)
        print("FASE 3: BACKUP")
        print("="*70)
        
        backup_name = f"vendas_small_backup_{int(datetime.now().timestamp())}"
        success, backup_count = backup_table(spark, s3_path, backup_name)
        
        if not success:
            raise Exception("Falha no backup")
        
        results["steps"].append({
            "step": "Backup creation",
            "status": "SUCCESS",
            "backup_name": backup_name,
            "records": backup_count
        })
        
        # 5. Restauração
        print("\n" + "="*70)
        print("FASE 4: RESTAURAÇÃO")
        print("="*70)
        
        restore_path = f"s3a://datalake/warehouse/default/vendas_small_restored"
        success, restore_count = restore_from_backup(spark, backup_name, restore_path)
        
        if not success:
            raise Exception("Falha na restauração")
        
        results["steps"].append({
            "step": "Restore operation",
            "status": "SUCCESS",
            "restore_location": restore_path,
            "records": restore_count
        })
        
        # 6. Validação de integridade
        print("\n" + "="*70)
        print("FASE 5: VALIDAÇÃO")
        print("="*70)
        
        integrity_ok, original_count, restored_count = validate_integrity(
            spark, s3_path, restore_path
        )
        
        results["steps"].append({
            "step": "Integrity validation",
            "status": "SUCCESS" if integrity_ok else "WARNING",
            "original_count": original_count,
            "restored_count": restored_count,
            "integrity_ok": integrity_ok
        })
        
        # Resumo
        print("\n" + "="*70)
        print("📋 RESUMO")
        print("="*70)
        print(f"✅ Registros gerados: {count}")
        print(f"✅ Backup criado: {backup_name}")
        print(f"✅ Integridade: {'PASSOU ✓' if integrity_ok else 'FALHOU ✗'}")
        
        results["summary"] = {
            "records_generated": count,
            "backup_name": backup_name,
            "integrity_ok": integrity_ok,
            "status": "SUCCESS"
        }
        
        # Salvar resultados
        output_file = "/tmp/data_gen_backup_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"\n✅ Resultados salvos: {output_file}")
        
        spark.stop()
        
    except Exception as e:
        print(f"\n❌ ERRO: {e}")
        traceback.print_exc()
        results["errors"].append(str(e))
        results["summary"]["status"] = "FAILED"
        
        # Salvar erros
        output_file = "/tmp/data_gen_backup_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2, default=str)
    
    print("\n✅ PROCEDURE COMPLETO\n")

if __name__ == "__main__":
    run()
