#!/usr/bin/env python3
"""
Disaster Recovery Procedimento - SIMPLIFICADO
Para Iteration 4 - Production Hardening
Cria checkpoint e restaura, sem simulação de corrupção
"""

import json
import traceback
from datetime import datetime
from pyspark.sql import SparkSession
import os

def run():
    """Executa procedimento simplificado de DR"""
    
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
        checkpoint_ts = int(datetime.now().timestamp())
        checkpoint_dir = f"/home/datalake/checkpoints/checkpoint_{checkpoint_ts}"
        
        print(f"\n📸 Criando checkpoint...")
        
        os.system(f"mkdir -p {checkpoint_dir}")
        
        df = spark.read.parquet(data_path)
        orig_count = df.count()
        
        df.write \
            .mode("overwrite") \
            .parquet(checkpoint_dir)
        
        print(f"✅ Checkpoint criado")
        print(f"✓ Registros: {orig_count}")
        
        results["steps"].append({
            "step": "Checkpoint creation",
            "status": "SUCCESS",
            "checkpoint_location": checkpoint_dir,
            "records": orig_count
        })
        
        # 3. Simular perda de dados (deletar dados originais)
        print("\n" + "="*70)
        print("FASE 2: SIMULAÇÃO DE CENÁRIO DE DESASTRE")
        print("="*70)
        
        print(f"\n⚠️  Simulando perda de dados (deletando dados originais)...")
        
        os.system(f"rm -rf {data_path}/*")
        
        print(f"✅ Dados removidos")
        
        results["steps"].append({
            "step": "Disaster simulation",
            "status": "SUCCESS",
            "action": "Deleted original data"
        })
        
        # 4. Recuperar do checkpoint
        print("\n" + "="*70)
        print("FASE 3: RECUPERAÇÃO DO CHECKPOINT")
        print("="*70)
        
        print(f"\n🔄 Restaurando dados do checkpoint...")
        
        df_checkpoint = spark.read.parquet(checkpoint_dir)
        recovered_count = df_checkpoint.count()
        
        df_checkpoint.write \
            .mode("overwrite") \
            .parquet(data_path)
        
        print(f"✅ Recuperação completada")
        print(f"✓ Registros restaurados: {recovered_count}")
        
        results["steps"].append({
            "step": "Recovery from checkpoint",
            "status": "SUCCESS",
            "recovered_records": recovered_count
        })
        
        # 5. Validar recuperação
        print("\n" + "="*70)
        print("FASE 4: VALIDAÇÃO")
        print("="*70)
        
        print(f"\n✓ Validando recuperação...")
        
        df_verify = spark.read.parquet(data_path)
        verify_count = df_verify.count()
        
        print(f"Contagem original:    {orig_count}")
        print(f"Contagem recuperada:  {verify_count}")
        
        recovery_valid = (orig_count == verify_count)
        
        if recovery_valid:
            print(f"✅ Dados validados com sucesso")
        else:
            print(f"⚠️  Aviso: contagens diferentes!")
        
        # Amostra dos dados
        print(f"\n📋 Amostra dos dados recuperados:")
        df_verify.show(5)
        
        results["steps"].append({
            "step": "Validation",
            "status": "SUCCESS" if recovery_valid else "WARNING",
            "original_count": orig_count,
            "recovered_count": verify_count,
            "validation_passed": recovery_valid
        })
        
        # Resumo
        print("\n" + "="*70)
        print("📋 RESUMO DO DISASTER RECOVERY")
        print("="*70)
        print(f"✅ Checkpoint criado: checkpoint_{checkpoint_ts}")
        print(f"✅ Cenário de desastre simulado")
        print(f"✅ Recuperação: {recovered_count} registros")
        print(f"✅ Validação: {'PASSOU ✓' if recovery_valid else 'FALHOU ✗'}")
        
        results["summary"] = {
            "checkpoint_timestamp": checkpoint_ts,
            "checkpoint_location": checkpoint_dir,
            "original_records": orig_count,
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
