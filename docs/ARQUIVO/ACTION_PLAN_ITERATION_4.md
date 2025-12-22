# Plano de Ação: Finalizar Iteration 4

> 📌 **NOTA:** Este arquivo é referência histórica. Para status consolidado e índice de documentação, consulte [`docs/INDICE_DOCUMENTACAO.md`](docs/INDICE_DOCUMENTACAO.md)

---

## 🎯 Objetivo
Resolver problema de Iceberg catalog e executar testes de backup/restore + disaster recovery

---

## 🔴 Problema Atual

```
ClassNotFoundException: org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
```

**Contexto**:
- ✅ test_compaction.py funciona perfeitamente
- ❌ Novos scripts Python não conseguem carregar Iceberg
- Difference: Exatamente a mesma configuração SparkSession

---

## ✅ Solução Comprovada

### 1. Usar Configuração Exata de test_compaction.py

**O que funciona**:
```python
self.spark = SparkSession.builder \
    .appName("...") \
    .master("local[2]") \
    .config("spark.sql.extensions", 
           "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .config("spark.sql.catalog.hadoop_prod", 
           "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
    .config("spark.sql.catalog.hadoop_prod.warehouse", 
           "s3a://datalake/warehouse") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://localhost:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "spark_user") \
    .config("spark.hadoop.fs.s3a.secret.key", "SparkPass123!") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", 
           "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.jars.packages", 
           "org.apache.hadoop:hadoop-aws:3.3.4," \
           "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
    .getOrCreate()
```

### 2. Estilo de Classe

**Estrutura de test_compaction.py**:
```python
class CompactionManager:
    def __init__(self):
        self.spark = SparkSession.builder...
        
    def run(self):
        # Main workflow
        
    def method1(self):
        # Use self.spark.sql()
```

**Uso**:
```python
if __name__ == "__main__":
    manager = CompactionManager()
    manager.run()
```

---

## 🚀 Passos Executivos

### Passo 1: Backup/Restore (15 minutos)

#### 1a. Criar novo script baseado em test_compaction.py
```bash
ssh datalake@192.168.4.33 << 'EOF'
cat > /home/datalake/test_backup_restore_v2.py << 'PYEOF'
# Copiar structure de test_compaction.py
# Substituir métodos:
# - Em vez de get_table_metrics_baseline()
# + create_backup(table_name, backup_name)
# - Em vez de benchmark_queries()
# + restore_backup(backup_name, restore_table_name)
# - Em vez de validate_data_integrity()
# + validate_backup_integrity(original_table, backup_name)
PYEOF

# Executar
/home/datalake/.local/lib/python3.11/site-packages/pyspark/bin/spark-submit \
  --master local[2] \
  --driver-memory 2g \
  --executor-memory 2g \
  /home/datalake/test_backup_restore_v2.py
EOF
```

#### 1b. Copiar resultado
```bash
scp datalake@192.168.4.33:/tmp/backup_restore_v2_results.json .
```

### Passo 2: Disaster Recovery (15 minutos)

#### 2a. Criar novo script baseado em test_compaction.py
```bash
# Mesma estrutura, adaptar métodos:
# + create_checkpoint(table_name)
# + simulate_data_corruption(table_name)
# + recover_to_checkpoint(table_name, checkpoint)
# + validate_recovery(table_name, checkpoint)
```

#### 2b. Executar e copiar resultado
```bash
ssh datalake@192.168.4.33 "spark-submit ... test_disaster_recovery_v2.py"
scp datalake@192.168.4.33:/tmp/disaster_recovery_v2_results.json .
```

### Passo 3: Análise (10 minutos)

#### 3a. Validar sucesso
```bash
cat backup_restore_v2_results.json | grep '"status"'
cat disaster_recovery_v2_results.json | grep '"status"'
```

#### 3b. Documentar resultados
- Copiar exemplos em ITERATION_4_RESULTS_FINAL.md
- Atualizar PROJECT_STATUS_SUMMARY.md (75%)

---

## 📝 Template para Novo Script

Use este template como base:

```python
#!/usr/bin/env python3
"""
Iteration 4: Backup/Restore (TEMPLATE)
======================================
Baseado em test_compaction.py
"""

import os
import json
import time
from datetime import datetime
from pathlib import Path
from pyspark.sql import SparkSession


class BackupRestoreManager:
    """Handle table backup and restore"""
    
    def __init__(self):
        """Initialize Spark with ICEBERG - Cópia EXATA de test_compaction.py"""
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
            .config("spark.hadoop.fs.s3a.endpoint", "http://localhost:9000") \
            .config("spark.hadoop.fs.s3a.access.key", "spark_user") \
            .config("spark.hadoop.fs.s3a.secret.key", "SparkPass123!") \
            .config("spark.hadoop.fs.s3a.path.style.access", "true") \
            .config("spark.hadoop.fs.s3a.impl", 
                   "org.apache.hadoop.fs.s3a.S3AFileSystem") \
            .config("spark.jars.packages", 
                   "org.apache.hadoop:hadoop-aws:3.3.4," \
                   "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0") \
            .getOrCreate()
        
        self.spark.sparkContext.setLogLevel("WARN")
        self.backup_dir = "/home/datalake/backups"
        os.makedirs(self.backup_dir, exist_ok=True)
    
    def create_backup(self, table_name, backup_name=None):
        """Sua implementação aqui"""
        pass
    
    def restore_backup(self, backup_name, restore_table_name):
        """Sua implementação aqui"""
        pass
    
    def validate_backup_integrity(self, original_table, backup_name):
        """Sua implementação aqui"""
        pass
    
    def run(self):
        """Main workflow"""
        print("\n" + "="*70)
        print("💾 BACKUP & RESTORE - ITERATION 4")
        print("="*70)
        
        table_name = "hadoop_prod.default.vendas_small"
        
        # Call your methods
        backup_result = self.create_backup(table_name)
        restore_result = self.restore_backup("backup_name", "restore_table")
        integrity_result = self.validate_backup_integrity(table_name, "backup_name")
        
        # Save results
        results = {
            "timestamp": datetime.now().isoformat(),
            "backup": backup_result,
            "restore": restore_result,
            "integrity": integrity_result
        }
        
        with open("/tmp/backup_restore_v2_results.json", "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"✅ Resultados salvos")


if __name__ == "__main__":
    manager = BackupRestoreManager()
    manager.run()
```

---

## 📊 Checklist de Execução

- [ ] Criar test_backup_restore_v2.py (baseado em template)
- [ ] Copiar para servidor
- [ ] Executar e capturar resultado
- [ ] Criar test_disaster_recovery_v2.py
- [ ] Copiar para servidor
- [ ] Executar e capturar resultado
- [ ] Validar sucesso (status == "SUCCESS")
- [ ] Copiar JSON results de volta
- [ ] Atualizar ITERATION_4_RESULTS_FINAL.md
- [ ] Atualizar PROJECT_STATUS_SUMMARY.md (75%)

---

## 🎯 Critério de Sucesso

### Para Backup/Restore
```json
{
  "backup": {
    "status": "SUCCESS",
    "row_count": 50000,
    "size_mb": > 0
  },
  "restore": {
    "status": "SUCCESS",
    "rows_restored": 50000
  },
  "integrity": {
    "integrity_status": "VALID",
    "match": true
  }
}
```

### Para Disaster Recovery
```json
{
  "checkpoint": "SUCCESS",
  "corruption_simulation": "SUCCESS",
  "recovery": {
    "status": "SUCCESS",
    "rto_seconds": < 300
  },
  "validation": "SUCCESS"
}
```

---

## ⏱️ Timeline Estimado

| Passo | Tempo | Status |
|-------|-------|--------|
| Criar backup_restore_v2.py | 10 min | ⏳ |
| Copiar e executar | 5 min | ⏳ |
| Criar disaster_recovery_v2.py | 10 min | ⏳ |
| Copiar e executar | 5 min | ⏳ |
| Validar e documentar | 10 min | ⏳ |
| **TOTAL** | **40 min** | ⏳ |

---

## 🎁 Entrega Final

Após conclusão:

1. ✅ 3 scripts Iteration 4 funcionando
2. ✅ 5 testes executados com sucesso
3. ✅ 5 arquivos JSON com resultados
4. ✅ Documentação completa (ITERATION_4_RESULTS_FINAL.md)
5. ✅ Project status 75% completo
6. ✅ Roadmap para Iteration 5 pronto

**Resultado**: Projeto no caminho para 100% de conclusão

---

**Criado**: 2025-12-07 15:00 UTC  
**Status**: Plano pronto para execução  
**Próxima ação**: Executar passos acima
