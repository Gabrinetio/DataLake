#!/usr/bin/env python3
"""
Geração de Dados + Backup/Restore Procedimento
SIMPLIFICADO - salva em HDFS local, não S3
Para Iteration 4 - Production Hardening
"""

import json
import traceback
from datetime import datetime, timedelta
import random
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, IntegerType, TimestampType
import os

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

def run():
    """Executa todo o procedimento"""
    
    print("\n" + "="*70)
    print("🚀 GERAÇÃO DE DADOS + BACKUP/RESTORE SIMPLIFICADO - ITERATION 4")
    print("="*70)
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "steps": [],
        "summary": {},
        "errors": []
    }
    
    try:
        # 1. Criar SparkSession (sem S3A extensions)
        print("\n🔧 Iniciando SparkSession...")
        
        spark = SparkSession.builder \
            .appName("DataGen_Backup_Restore_Local") \
            .master("local[2]") \
            .getOrCreate()
        
        print("✅ SparkSession criada")
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
        count = df_vendas.count()
        print(f"✅ {count} registros gerados")
        
        results["steps"].append({
            "step": "Data generation",
            "status": "SUCCESS",
            "records": count
        })
        
        # 3. Criar diretório de dados
        print("\n" + "="*70)
        print("FASE 2: CRIAÇÃO DE TABELA")
        print("="*70)
        
        data_path = "/home/datalake/data/vendas_small"
        backup_base = "/home/datalake/backups"
        
        # Criar diretórios
        os.system(f"mkdir -p {data_path}")
        os.system(f"mkdir -p {backup_base}")
        
        # Limpar dados antigos
        os.system(f"rm -rf {data_path}/*")
        
        # Salvar como Parquet
        print(f"\n💾 Salvando tabela em: {data_path}...")
        
        df_vendas.write \
            .mode("overwrite") \
            .parquet(data_path)
        
        print(f"✅ Tabela salva")
        
        # Verificar
        df_verify = spark.read.parquet(data_path)
        verify_count = df_verify.count()
        print(f"✓ Verificação: {verify_count} registros")
        
        results["steps"].append({
            "step": "Table creation",
            "status": "SUCCESS",
            "location": data_path,
            "records": verify_count
        })
        
        # 4. Backup
        print("\n" + "="*70)
        print("FASE 3: BACKUP")
        print("="*70)
        
        backup_timestamp = int(datetime.now().timestamp())
        backup_name = f"vendas_small_backup_{backup_timestamp}"
        backup_path = f"{backup_base}/{backup_name}"
        
        print(f"\n🔄 Criando backup: {backup_name}...")
        
        # Remover se já existe
        os.system(f"rm -rf {backup_path}")
        
        df_vendas.write \
            .mode("overwrite") \
            .parquet(backup_path)
        
        # Verificar backup
        df_backup_verify = spark.read.parquet(backup_path)
        backup_count = df_backup_verify.count()
        
        print(f"✅ Backup criado: {backup_path}")
        print(f"✓ Registros: {backup_count}")
        
        results["steps"].append({
            "step": "Backup creation",
            "status": "SUCCESS",
            "backup_name": backup_name,
            "backup_path": backup_path,
            "records": backup_count
        })
        
        # 5. Restauração
        print("\n" + "="*70)
        print("FASE 4: RESTAURAÇÃO")
        print("="*70)
        
        restore_path = f"{backup_base}/{backup_name}_restored"
        
        print(f"\n↩️  Restaurando backup para: {restore_path}...")
        
        # Remover se já existe
        os.system(f"rm -rf {restore_path}")
        
        df_backup = spark.read.parquet(backup_path)
        df_backup.write \
            .mode("overwrite") \
            .parquet(restore_path)
        
        # Verificar restauração
        df_restore_verify = spark.read.parquet(restore_path)
        restore_count = df_restore_verify.count()
        
        print(f"✅ Restaurado para: {restore_path}")
        print(f"✓ Registros: {restore_count}")
        
        results["steps"].append({
            "step": "Restore operation",
            "status": "SUCCESS",
            "restore_path": restore_path,
            "records": restore_count
        })
        
        # 6. Validação de integridade
        print("\n" + "="*70)
        print("FASE 5: VALIDAÇÃO")
        print("="*70)
        
        print(f"\n✓ Validando integridade...")
        
        original_count = spark.read.parquet(data_path).count()
        backup_check = spark.read.parquet(backup_path).count()
        restore_check = spark.read.parquet(restore_path).count()
        
        print(f"Original:  {original_count} registros")
        print(f"Backup:    {backup_check} registros")
        print(f"Restaurado: {restore_check} registros")
        
        integrity_ok = (original_count == backup_check == restore_check)
        
        if integrity_ok:
            print(f"✅ Integridade OK - todas as contagens idênticas")
        else:
            print(f"⚠️  Aviso: contagens diferentes!")
        
        results["steps"].append({
            "step": "Integrity validation",
            "status": "SUCCESS" if integrity_ok else "WARNING",
            "original_count": original_count,
            "backup_count": backup_check,
            "restore_count": restore_check,
            "integrity_ok": integrity_ok
        })
        
        # Resumo
        print("\n" + "="*70)
        print("📋 RESUMO")
        print("="*70)
        print(f"✅ Registros gerados: {original_count}")
        print(f"✅ Backup criado: {backup_name}")
        print(f"✅ Integridade: {'PASSOU ✓' if integrity_ok else 'FALHOU ✗'}")
        
        results["summary"] = {
            "records_generated": original_count,
            "backup_name": backup_name,
            "backup_path": backup_path,
            "restore_path": restore_path,
            "integrity_ok": integrity_ok,
            "status": "SUCCESS"
        }
        
        spark.stop()
        
    except Exception as e:
        print(f"\n❌ ERRO: {e}")
        traceback.print_exc()
        results["errors"].append(str(e))
        results["summary"]["status"] = "FAILED"
    
    # Salvar resultados
    output_file = "/tmp/data_gen_backup_results.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\n✅ Resultados salvos: {output_file}\n")

if __name__ == "__main__":
    run()
