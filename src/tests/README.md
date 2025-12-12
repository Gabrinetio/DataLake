# 🧪 src/tests/ - Scripts de Teste

Todos os scripts de teste do projeto DataLake FB.

## 📋 Organização por Iteração

### ✅ Iteração 1 - Data Generation & Benchmark
- `test_benchmark.py` - Benchmark de queries
- `test_simple_benchmark.py` - Versão simplificada
- `test_data_generator.py` - Geração de dados
- `test_simple_data_gen.py` - Versão simplificada
- `test_spark_access.py` - Verificação de acesso Spark

### ✅ Iteração 2 - Time Travel & MERGE INTO
- `test_time_travel.py` - Snapshots e time travel
- `test_merge_into.py` - Operações MERGE INTO
- `test_snapshot_lifecycle.py` - Ciclo de vida de snapshots

### ✅ Iteração 3 - Compaction & Monitoring
- `test_compaction.py` - Compaction de arquivos
- `test_iceberg_optimization.py` - Otimizações Iceberg
- `test_iceberg_partitioned.py` - Particionamento Iceberg
- `test_monitoring.py` - Monitoramento de performance

### ✅ Iteração 4 - Production Hardening

#### Backup & Restore
- `test_data_gen_and_backup_local.py` ⭐ (versão final)
- `test_data_gen_and_backup.py` (anterior)
- `test_backup_restore_v3.py` (versão 3)
- `test_backup_restore_v2.py` (versão 2)
- `test_backup_restore_final.py` (anterior)
- `test_backup_restore_simple.py` (anterior)
- `test_backup_restore.py` (primeira versão)

#### Disaster Recovery
- `test_disaster_recovery_final.py` ⭐ (versão final)
- `test_disaster_recovery_v2.py` (versão 2)
- `test_disaster_recovery_simple.py` (anterior)
- `test_disaster_recovery.py` (primeira versão)

#### Segurança & Diagnóstico
- `test_security_hardening.py` - Auditoria de segurança
- `test_diagnose_tables.py` - Diagnóstico do catálogo

## 🚀 Como Executar

```bash
# Na raiz do projeto
cd src/tests/

# Executar script específico
python test_data_gen_and_backup_local.py

# Ver resultado
ls -la ../results/

# Analisar resultado JSON
cat ../results/data_gen_backup_results.json | python -m json.tool
```

## 📊 Status de Testes

| Status | Iteração | Contagem |
|--------|----------|----------|
| ✅ Passando | 1 | 5 testes |
| ✅ Passando | 2 | 3 testes |
| ✅ Passando | 3 | 4 testes |
| ✅ Passando | 4 | 7 testes |
| **TOTAL** | - | **19 testes** |

## 📝 Versões dos Scripts

> **Dica:** Use sempre a versão com `_final` ou sem sufixo de versão, pois foram validadas.

### Variações de Backup/Restore
- `test_backup_restore.py` (v1) - Primeira tentativa
- `test_backup_restore_simple.py` - Simplificada
- `test_backup_restore_v2.py` (v2) - Segunda tentativa
- `test_backup_restore_v3.py` (v3) - Terceira tentativa
- `test_backup_restore_final.py` - Antes de Parquet workaround
- `test_data_gen_and_backup_local.py` ⭐ - **VERSÃO ATIVA**

### Variações de Disaster Recovery
- `test_disaster_recovery.py` (v1) - Primeira tentativa
- `test_disaster_recovery_simple.py` - Simplificada
- `test_disaster_recovery_v2.py` (v2) - Segunda tentativa
- `test_disaster_recovery_final.py` ⭐ - **VERSÃO ATIVA**

## 🔑 Scripts Ativos (Usar estes)

```
⭐ test_data_gen_and_backup_local.py
⭐ test_disaster_recovery_final.py
⭐ test_compaction.py
⭐ test_monitoring.py
⭐ test_security_hardening.py
```

## 📚 Referências

- [`docs/INDICE_DOCUMENTACAO.md`](../../docs/INDICE_DOCUMENTACAO.md) - Índice geral
- [`docs/Projeto.md`](../../docs/Projeto.md) - Arquitetura e detalhes
- [`artifacts/results/`](../artifacts/results/) - Resultados de execução
