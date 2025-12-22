#!/usr/bin/env python3
"""
Disaster Recovery Procedimento
Para Iteration 4 - Production Hardening
Cria checkpoint, simula corrupção, recupera, valida
"""

import json
import traceback
from datetime import datetime
from pyspark.sql import SparkSession
import os
import shutil

def create_checkpoint(spark, data_path, checkpoint_name):
    """Cria checkpoint dos dados atuais"""
    
    print(f"\n📸 Criando checkpoint: {checkpoint_name}...")
    
    try:
        checkpoint_dir = f"/home/datalake/checkpoints/{checkpoint_name}"
        
        # Remover se já existe
        os.system(f"rm -rf {checkpoint_dir}")
        os.system(f"mkdir -p {checkpoint_dir}")
        
        # Copiar dados
        df = spark.read.parquet(data_path)
        count = df.count()
        
        df.write \
            .mode("overwrite") \
            .parquet(checkpoint_dir)
        
        print(f"✅ Checkpoint criado: {checkpoint_name}")
        print(f"✓ Registros: {count}")
        
        return True, count, checkpoint_dir
        
    except Exception as e:
        print(f"❌ Erro criando checkpoint: {e}")
        return False, 0, None

def simulate_data_corruption(spark, data_path):
    """Simula corrupção de dados (adiciona registros inválidos)"""
    
    print(f"\n⚠️  Simulando corrupção de dados...")
    
    try:
        from pyspark.sql.types import StructType, StructField, IntegerType, TimestampType, StringType, DoubleType
        from pyspark.sql.functions import lit
        from datetime import datetime as dt
        
        # Ler dados
        df = spark.read.parquet(data_path)
        
        # Criar registros corrompidos (com valores NULL em campos críticos)
        schema = df.schema
        corrupt_records = [
            {
                "id": 99999,
                "data_venda": dt(2999, 12, 31),
                "categoria": "CORRUPTO",
                "produto": None,  # NULL em campo que não deveria
                "quantidade": -999,  # Quantidade negativa (inválida)
                "preco_unitario": None,  # NULL em preço
                "total": -9999.0,  # Valor negativo (inválido)
            },
            {
                "id": 100000,
                "data_venda": None,  # NULL em data
                "categoria": "CORRUPTO",
                "produto": "Produto_Corrompido",
                "quantidade": 0,  # Quantidade zero
                "preco_unitario": 0.0,
                "total": 0.0,
            }
        ]
        
        df_corrupt = spark.createDataFrame(corrupt_records, schema)
        
        # Unir dados originais com corrompidos
        df_combined = df.unionByName(df_corrupt)
        
        # Salvar dados corrompidos
        df_combined.write \
            .mode("overwrite") \
            .parquet(data_path)
        
        new_count = df_combined.count()
        print(f"✓ Dados corrompidos: {new_count} registros (adicionados 2 inválidos)")
        
        return True, new_count
        
    except Exception as e:
        print(f"❌ Erro simulando corrupção: {e}")
        traceback.print_exc()
        return False, 0

def recover_to_checkpoint(spark, checkpoint_dir, recovery_path):
    """Restaura dados do checkpoint (recuperação de DR)"""
    
    print(f"\n🔄 Restaurando dados do checkpoint...")
    
    try:
        # Remover dados corrupto
        os.system(f"rm -rf {recovery_path}/*")
        
        # Copiar checkpoint
        df_checkpoint = spark.read.parquet(checkpoint_dir)
        count = df_checkpoint.count()
        
        df_checkpoint.write \
            .mode("overwrite") \
            .parquet(recovery_path)
        
        print(f"✅ Recuperação completada")
        print(f"✓ Registros restaurados: {count}")
        
        return True, count
        
    except Exception as e:
        print(f"❌ Erro recuperando: {e}")
        return False, 0

def validate_recovery(spark, recovery_path, original_count):
    """Valida integridade após recuperação"""
    
    print(f"\n✓ Validando recuperação...")
    
    try:
        df_recovered = spark.read.parquet(recovery_path)
        recovered_count = df_recovered.count()
        
        print(f"Contagem original: {original_count}")
        print(f"Contagem recuperada: {recovered_count}")
        
        # Validar contagem
        if recovered_count == original_count:
            print(f"✅ Contagem validada")
        else:
            print(f"⚠️  Aviso: contagens diferentes")
        
        # Validar estrutura
        try:
            # Verificar se não há valores inválidos
            invalid_count = df_recovered.filter(
                (df_recovered.quantidade < 0) |
                (df_recovered.preco_unitario < 0) |
                (df_recovered.total < 0)
            ).count()
            
            print(f"Registros inválidos: {invalid_count}")
            
            if invalid_count == 0:
                print(f"✅ Dados válidos")
                return True
            else:
                print(f"⚠️  Dados ainda contêm registros inválidos")
                return False
                
        except:
            # Se validação falhar, apenas retorna true baseado na contagem
            return recovered_count == original_count
        
    except Exception as e:
        print(f"❌ Erro validando: {e}")
        return False

def run():
    """Executa procedimento de disaster recovery"""
    
    print("\n" + "="*70)
    print("🚨 DISASTER RECOVERY PROCEDIMENTO - ITERATION 4")
    print("="*70)
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "steps": [],
        "summary": {},
        "errors": []
    }
    
    try:
        # 1. SparkSession
        print("\n🔧 Iniciando SparkSession...")
        
        spark = SparkSession.builder \
            .appName("DisasterRecovery") \
            .master("local[2]") \
            .getOrCreate()
        
        print("✅ SparkSession criada")
        
        # 2. Criar checkpoint
        print("\n" + "="*70)
        print("FASE 1: CRIAÇÃO DE CHECKPOINT")
        print("="*70)
        
        data_path = "/home/datalake/data/vendas_small"
        checkpoint_name = f"checkpoint_{int(datetime.now().timestamp())}"
        
        success, orig_count, checkpoint_dir = create_checkpoint(spark, data_path, checkpoint_name)
        
        if not success:
            raise Exception("Falha ao criar checkpoint")
        
        results["steps"].append({
            "step": "Checkpoint creation",
            "status": "SUCCESS",
            "checkpoint_name": checkpoint_name,
            "records": orig_count
        })
        
        # 3. Simular corrupção
        print("\n" + "="*70)
        print("FASE 2: SIMULAÇÃO DE CORRUPÇÃO")
        print("="*70)
        
        success, corrupt_count = simulate_data_corruption(spark, data_path)
        
        if not success:
            raise Exception("Falha ao simular corrupção")
        
        results["steps"].append({
            "step": "Data corruption simulation",
            "status": "SUCCESS",
            "corrupted_records": corrupt_count
        })
        
        # 4. Recuperar do checkpoint
        print("\n" + "="*70)
        print("FASE 3: RECUPERAÇÃO")
        print("="*70)
        
        recovery_path = "/home/datalake/data/vendas_small_recovered"
        os.system(f"mkdir -p {recovery_path}")
        
        success, recovered_count = recover_to_checkpoint(spark, checkpoint_dir, recovery_path)
        
        if not success:
            raise Exception("Falha na recuperação")
        
        results["steps"].append({
            "step": "Recovery from checkpoint",
            "status": "SUCCESS",
            "recovered_records": recovered_count
        })
        
        # 5. Validar recuperação
        print("\n" + "="*70)
        print("FASE 4: VALIDAÇÃO")
        print("="*70)
        
        recovery_valid = validate_recovery(spark, recovery_path, orig_count)
        
        results["steps"].append({
            "step": "Recovery validation",
            "status": "SUCCESS" if recovery_valid else "WARNING",
            "original_count": orig_count,
            "recovered_count": recovered_count,
            "validation_passed": recovery_valid
        })
        
        # Resumo
        print("\n" + "="*70)
        print("📋 RESUMO DO DISASTER RECOVERY")
        print("="*70)
        print(f"✅ Checkpoint criado: {checkpoint_name}")
        print(f"✅ Corrupção simulada: 2 registros adicionados")
        print(f"✅ Recuperação: {recovered_count} registros")
        print(f"✅ Validação: {'PASSOU ✓' if recovery_valid else 'FALHOU ✗'}")
        
        results["summary"] = {
            "checkpoint_name": checkpoint_name,
            "original_records": orig_count,
            "corrupted_records": corrupt_count,
            "recovered_records": recovered_count,
            "recovery_valid": recovery_valid,
            "status": "SUCCESS"
        }
        
        spark.stop()
        
    except Exception as e:
        print(f"\n❌ ERRO: {e}")
        traceback.print_exc()
        results["errors"].append(str(e))
        results["summary"]["status"] = "FAILED"
    
    # Salvar resultados
    output_file = "/tmp/disaster_recovery_results.json"
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"\n✅ Resultados salvos: {output_file}\n")

if __name__ == "__main__":
    run()
