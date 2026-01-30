#!/usr/bin/env python3
"""
Iteração 4: Backup e Restauração - Versão Final
============================================

Propósito:
  - Criar backups de tabelas usando exportação Parquet
  - Implementar procedimentos de restauração
  - Validar integridade do backup
"""

import os
import json
import time
from datetime import datetime
from pathlib import Path
from pyspark.sql import SparkSession
from src.config import get_spark_s3_config


class BackupRestoreManager:
    """Gerencia backup e restauração de tabelas usando Iceberg"""
    
    def __init__(self):
        """Inicializa sessão Spark com Iceberg"""
        spark_config = get_spark_s3_config()
        self.spark = SparkSession.builder \
            .appName("Iceberg_Backup_Restore") \
            .master("local[2]") \
            .config("spark.sql.extensions", 
                   "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
            .config("spark.sql.catalog.hadoop_prod", 
                   "org.apache.iceberg.spark.SparkCatalog") \
            .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
            .config("spark.sql.catalog.hadoop_prod.warehouse", 
                   "s3a://datalake/warehouse") \
            .config("spark.jars.packages", 
                   "org.apache.hadoop:hadoop-aws:3.3.4," \
                   "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        print("\n✅ SparkSession inicializada\n")
        
        self.backup_dir = "/home/datalake/backups"
        os.makedirs(self.backup_dir, exist_ok=True)
        os.chmod(self.backup_dir, 0o777)
    
    def create_backup(self, table_name, backup_name=None):
        """Cria um backup dos dados da tabela"""
        print(f"\n💾 CRIANDO BACKUP para {table_name}")
        print("=" * 70)
        
        if backup_name is None:
            backup_name = f"backup_{int(time.time())}"
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Ler da tabela Iceberg
            df = self.spark.sql(f"SELECT * FROM {table_name}")
            num_rows = df.count()
            
            # Exportar para Parquet
            df.coalesce(1).write.mode("overwrite").parquet(backup_path)
            
            elapsed = time.time() - start_time
            
            # Obter metadados do backup
            backup_size = sum(f.stat().st_size for f in Path(backup_path).rglob("*") if f.is_file())
            
            backup_info = {
                "backup_name": backup_name,
                "table": table_name,
                "row_count": num_rows,
                "size_bytes": backup_size,
                "size_mb": backup_size / (1024**2),
                "backup_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "path": backup_path,
                "status": "SUCESSO"
            }
            
            print(f"  ✅ Backup criado: {backup_name}")
            print(f"  📝 Linhas: {num_rows:,}")
            print(f"  💾 Tamanho: {backup_info['size_mb']:.2f} MB")
            print(f"  ⏱️  Tempo: {elapsed:.2f}s")
            
            return backup_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"  ❌ Falha no backup: {str(e)[:150]}")
            return {
                "backup_name": backup_name,
                "status": "FALHA",
                "error": str(e)[:150],
                "time_seconds": elapsed
            }
    
    def restore_backup(self, backup_name, restore_table_name):
        """Restaura um backup para uma nova tabela"""
        print(f"\n📥 RESTAURANDO BACKUP: {backup_name}")
        print("=" * 70)
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        start_time = time.time()
        
        try:
            # Verificar se o backup existe
            if not os.path.exists(backup_path):
                raise Exception(f"Caminho de backup não existe: {backup_path}")
            
            # Ler do backup
            restore_df = self.spark.read.parquet(backup_path)
            num_rows = restore_df.count()
            
            # Escrever para localização S3
            restore_path = f"s3a://datalake/warehouse/restored/{restore_table_name}"
            restore_df.write.mode("overwrite").parquet(restore_path)
            
            elapsed = time.time() - start_time
            
            restore_info = {
                "restore_name": restore_table_name,
                "backup_name": backup_name,
                "rows_restored": num_rows,
                "restore_time_seconds": elapsed,
                "timestamp": datetime.now().isoformat(),
                "path": restore_path,
                "status": "SUCESSO"
            }
            
            print(f"  ✅ Dados restaurados: {restore_table_name}")
            print(f"  📝 Linhas: {num_rows:,}")
            print(f"  ⏱️  Tempo: {elapsed:.2f}s")
            
            return restore_info
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"  ❌ Falha na restauração: {str(e)[:150]}")
            return {
                "restore_name": restore_table_name,
                "status": "FALHA",
                "error": str(e)[:150],
                "time_seconds": elapsed
            }
    
    def validate_backup_integrity(self, original_table, backup_name):
        """Valida integridade do backup"""
        print(f"\n✔️  VALIDANDO INTEGRIDADE DO BACKUP")
        print("=" * 70)
        
        backup_path = os.path.join(self.backup_dir, backup_name)
        
        try:
            # Obter dados originais
            original_df = self.spark.sql(f"SELECT * FROM {original_table}")
            original_count = original_df.count()
            
            # Obter dados do backup
            backup_df = self.spark.read.parquet(backup_path)
            backup_count = backup_df.count()
            
            match = original_count == backup_count
            
            result = {
                "original_rows": original_count,
                "backup_rows": backup_count,
                "match": match,
                "integrity_status": "VÁLIDO" if match else "DIVERGENTE"
            }
            
            print(f"  Linhas originais: {original_count:,}")
            print(f"  Linhas do backup: {backup_count:,}")
            print(f"  Status: {result['integrity_status']}")
            
            return result
            
        except Exception as e:
            print(f"  ❌ Validação falhou: {str(e)[:150]}")
            return {
                "status": "FALHA",
                "error": str(e)[:150]
            }
    
    def list_backups(self):
        """Lista todos os backups disponíveis"""
        print(f"\n📋 BACKUPS DISPONÍVEIS")
        print("=" * 70)
        
        try:
            backups = []
            if os.path.exists(self.backup_dir):
                for item in os.listdir(self.backup_dir):
                    item_path = os.path.join(self.backup_dir, item)
                    if os.path.isdir(item_path):
                        size = sum(f.stat().st_size for f in Path(item_path).rglob("*") if f.is_file())
                        backups.append({
                            "name": item,
                            "size_mb": size / (1024**2),
                            "path": item_path
                        })
            
            if backups:
                for backup in backups:
                    print(f"  📦 {backup['name']} ({backup['size_mb']:.2f} MB)")
            else:
                print(f"  ℹ️  Nenhum backup encontrado")
            
            return backups
            
        except Exception as e:
            print(f"  ❌ Erro ao listar backups: {str(e)[:150]}")
            return []
    
    def run(self):
        """Executa fluxo completo de backup/restauração"""
        print("\n" + "="*70)
        print("💾 PROCEDIMENTOS DE BACKUP E RESTAURAÇÃO - ITERAÇÃO 4")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        backup_name = f"vendas_backup_{int(time.time())}"
        
        # 1. Criar backup
        backup_result = self.create_backup(table_name, backup_name)
        
        # 2. Listar backups
        backups = self.list_backups()
        
        # 3. Validar integridade
        if backup_result.get("status") == "SUCESSO":
            integrity_result = self.validate_backup_integrity(table_name, backup_name)
        else:
            integrity_result = {"status": "PULADO", "reason": "Backup falhou"}
        
        # 4. Restaurar backup
        restore_result = self.restore_backup(backup_name, "vendas_restored")
        
        # 5. Resumo
        print(f"\n📊 RESUMO DE BACKUP E RESTAURAÇÃO")
        print("=" * 70)
        
        print(f"  ✅ Backup criado: {backup_result.get('status')}")
        if backup_result.get("status") == "SUCESSO":
            print(f"     Linhas: {backup_result.get('row_count'):,}, Tamanho: {backup_result.get('size_mb'):.2f}MB")
        
        print(f"  ✔️  Integridade do backup: {integrity_result.get('integrity_status', 'DESCONHECIDO')}")
        
        print(f"  ✅ Dados restaurados: {restore_result.get('status')}")
        if restore_result.get("status") == "SUCESSO":
            print(f"     Linhas: {restore_result.get('rows_restored'):,}")
        
        # 6. Salvar resultados
        results = {
            "timestamp": datetime.now().isoformat(),
            "table": table_name,
            "backup": backup_result,
            "integrity": integrity_result,
            "restore": restore_result,
            "backups_available": backups,
            "summary": {
                "backup_status": backup_result.get("status"),
                "integrity_status": integrity_result.get("integrity_status", "DESCONHECIDO"),
                "restore_status": restore_result.get("status"),
                "overall_success": (backup_result.get("status") == "SUCESSO" and 
                                   restore_result.get("status") == "SUCESSO")
            }
        }
        
        output_file = "/home/datalake/backup_restore_results.json"
        with open(output_file, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"\n✅ TESTE DE BACKUP E RESTAURAÇÃO COMPLETO")
        print(f"📁 Resultados salvos em: {output_file}")
        
        return results


if __name__ == "__main__":
    manager = BackupRestoreManager()
    manager.run()
