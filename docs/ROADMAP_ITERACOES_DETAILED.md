# Roadmap: 5 Iterações para DataLake Iceberg Production-Ready

**Timeline:** 10 semanas | **Começou:** 2025-12-07 | **Meta:** 2026-02-09

---

## 📊 Resumo Executivo

| Iter. | Nome | Foco | Status | Semanas |
|-------|------|------|--------|---------|
| 1 | **Baseline** | Validação + Performance | ✅ COMPLETO | 1-2 |
| 2 | **Time Travel & UPSERT** | Versionamento + Updates | 🚀 IN PROGRESS | 3-4 |
| 3 | **Compaction & Maintenance** | Otimização | ⏳ PLANNED | 5-6 |
| 4 | **Production Hardening** | Security + HA | ⏳ PLANNED | 7-8 |
| 5 | **Advanced Features** | CDC + RBAC | ⏳ PLANNED | 9-10 |

---

## 🔄 Iteration 1: Baseline Performance & Validation

**Status:** ✅ **COMPLETO** (2025-12-07)

### Deliverables
- ✅ Data generator: 50K records em 1.91s
- ✅ 10 benchmark queries com metrics
- ✅ Partition pruning validation
- ✅ OutOfMemory error resolved (2GB executor)
- ✅ ITERATION_1_RESULTS.md + benchmark_results.json

### Key Metrics
| Métrica | Valor |
|---------|-------|
| Tempo médio query | 1.599s |
| Query mais rápida | 0.343s (partition filter) |
| Compressão | 383KB (50K records) |
| Taxa sucesso | 100% |

### Handoff para Iter. 2
```
✅ Tabela criada: hadoop_prod.default.vendas_small
✅ Snapshots: 2 (v1=v2.metadata.json, current)
✅ Dados particionados por (year=2025, month=1-12)
✅ Ready para Time Travel tests
```

---

## 🕐 Iteration 2: Time Travel & Schema Evolution

**Timeline:** 2025-12-21 até 2026-01-04

### 2.1 Time Travel (Snapshots & Versioning)

#### Tasks
- [ ] **T2.1.1:** Criar tabela `time_travel_test` com snapshots
  - Setup: 10 records V1
  - Insert: +10 records V2
  - Read: V1, V2, Current
  
- [ ] **T2.1.2:** Validate `SELECT ... VERSION AS OF <snapshot_id>`
  - Comparar V1 (10 rows) vs V2 (20 rows)
  - Comparar V2 vs Current
  - Benchmark: time-travel query vs. full scan

- [ ] **T2.1.3:** Test snapshot retention
  - `SELECT * FROM table.snapshots` → listar todas
  - Verificar metadatas em S3
  - `EXPIRE_SNAPSHOTS` behavior

#### Arquivo
`test_time_travel.py` - 150 linhas
- Setup table com 2 batches
- Insertar 10 + 10 records
- Query via `VERSION AS OF`
- Compare snapshots

#### Validation
```sql
-- Snapshot ID V1
SELECT snapshot_id, committed_at 
FROM vendas_small.snapshots 
ORDER BY committed_at DESC LIMIT 1;

-- Query na V1
SELECT COUNT(*) FROM vendas_small VERSION AS OF 1948373279699042674;
-- Expected: 10
```

### 2.2 UPSERT via MERGE INTO

#### Tasks
- [ ] **T2.2.1:** Criar tabela `inventory` com dados iniciais (5 produtos)
  - Schema: product_id (PK), quantity, price, updated_at
  - Partition: (year, month)

- [ ] **T2.2.2:** Preparar `inventory_updates` com 5 records
  - 3 updates (quantity/price change)
  - 2 inserts (novos produtos)

- [ ] **T2.2.3:** Executar `MERGE INTO ... WHEN MATCHED ... WHEN NOT MATCHED`
  - Validar UPDATE de 3 registros
  - Validar INSERT de 2 registros
  - Total esperado: 7 records

#### Arquivo
`test_merge_into.py` - 200 linhas
- Create table + create temp table
- Initial load 5 products
- Prepare 3 updates + 2 inserts
- MERGE operation
- Validate: 7 records total

#### Validation
```sql
-- Antes: 5 records
SELECT COUNT(*) FROM inventory;

-- Merge
MERGE INTO inventory t USING inventory_updates s ON ...

-- Depois: 7 records
SELECT COUNT(*) FROM inventory;
-- Expected: 7

-- Verificar updates
SELECT product_id, quantity FROM inventory WHERE product_id IN ('PROD_001', 'PROD_002');
-- PROD_001: 50 (atualizado de 100)
```

### 2.3 Schema Evolution

#### Tasks
- [ ] **T2.3.1:** ADD COLUMN `category` STRING
  - Alter table vendas_small
  - Verificar que dados antigos não têm categoria

- [ ] **T2.3.2:** INSERT com nova coluna
  - Adicionar 10 records com category=NEW

- [ ] **T2.3.3:** Query vendas_small com/sem category
  - Validar que NULLs aparecem para v1 data
  - Validar que nova coluna aparece

#### Arquivo
`test_schema_evolution.py` - 150 linhas

### Deliverables
```
✅ test_time_travel.py
✅ test_merge_into.py
✅ test_schema_evolution.py
✅ ITERATION_2_RESULTS.md
✅ Snapshots metadata validation
```

### Success Criteria
- ✅ `VERSION AS OF` queries retornam dados corretos
- ✅ MERGE INTO insere + atualiza
- ✅ Schema evolution sem perder dados antigos
- ✅ 0 errors durante operações

---

## 🧹 Iteration 3: Compaction & Optimization

**Timeline:** 2026-01-05 até 2026-01-18

### 3.1 Data Compaction

#### Tasks
- [ ] **T3.1.1:** Baseline: medir fragmentação
  - `SELECT COUNT(data_files) FROM vendas_small.files`
  - Mostrar tamanho total vs. count de files

- [ ] **T3.1.2:** REWRITE DATA FILES
  - `ALTER TABLE vendas_small EXECUTE REWRITE DATA FILES`
  - Medir tempo de rewrite

- [ ] **T3.1.3:** Post-compaction metrics
  - Comparar files antes/depois
  - Comparar query performance

#### Arquivo
`test_compaction.py` - 180 linhas

### 3.2 Snapshot Lifecycle

#### Tasks
- [ ] **T3.2.1:** EXPIRE_SNAPSHOTS
  - Set retention: 7 days
  - Remover snapshots antigos

- [ ] **T3.2.2:** REMOVE_ORPHAN_FILES
  - Limpar arquivos órfãos em S3
  - Validar que não afeta queries

- [ ] **T3.2.3:** Monitorar cleanup
  - Logging de expired snapshots
  - Disk space recovery

#### Arquivo
`test_snapshot_lifecycle.py` - 150 linhas

### 3.3 Monitoring & Stats

#### Tasks
- [ ] **T3.3.1:** Collect table statistics
  - File count, row count, size
  - Partition distribution

- [ ] **T3.3.2:** Query analyzer
  - Logging: query time, partition pruning efficiency
  - Identify slow queries

#### Arquivo
`test_monitoring.py` - 200 linhas

### Deliverables
```
✅ test_compaction.py
✅ test_snapshot_lifecycle.py
✅ test_monitoring.py
✅ ITERATION_3_RESULTS.md
✅ Performance comparison report
```

### Success Criteria
- ✅ Compaction reduz file count em 50%+
- ✅ Query performance igual/melhor
- ✅ Orphan files removidos
- ✅ Snapshots expirados com sucesso

---

## 🔐 Iteration 4: Production Hardening

**Timeline:** 2026-01-19 até 2026-02-01

### 4.1 Security & Access Control

#### Tasks
- [ ] **T4.1.1:** IAM policies para Spark/Iceberg
  - S3 bucket policies
  - MinIO access logs

- [ ] **T4.1.2:** Credential rotation
  - Test changing spark_user password
  - Verify Spark still connects

- [ ] **T4.1.3:** Encryption at rest
  - S3A SSE-S3 setup
  - Verify MinIO encrypts data

### 4.2 High Availability & DR

#### Tasks
- [ ] **T4.2.1:** Backup strategy
  - S3 backup bucket replication
  - Metadata backup frequency

- [ ] **T4.2.2:** Restore procedure
  - Simular restore from backup
  - Verify data integrity

- [ ] **T4.2.3:** Disaster recovery test
  - "Destroy" e rebuild table
  - Validate restore time

### 4.3 Monitoring & Alerting

#### Tasks
- [ ] **T4.3.1:** Prometheus metrics
  - Spark metrics export
  - MinIO S3 metrics

- [ ] **T4.3.2:** Grafana dashboards
  - DataLake health dashboard
  - Query performance trends

- [ ] **T4.3.3:** Alerting rules
  - OOM > threshold
  - Query time > SLA
  - Snapshot growth

### Deliverables
```
✅ Security configuration guide
✅ Backup/restore procedure
✅ DR runbook
✅ Monitoring setup
✅ ITERATION_4_RESULTS.md
```

### Success Criteria
- ✅ Backup/restore em < 1 hora
- ✅ 0 security vulnerabilities
- ✅ Alertas funcionando
- ✅ RTO = 30 min, RPO = 5 min

---

## 🚀 Iteration 5: Advanced Features

**Timeline:** 2026-02-02 até 2026-02-09

### 5.1 Change Data Capture (CDC)

#### Tasks
- [ ] **T5.1.1:** CDC setup com Iceberg + Flink
  - Capture inserts/updates/deletes
  - Stream to Kafka

- [ ] **T5.1.2:** CDC consumer
  - Read from Kafka
  - Apply to downstream system

- [ ] **T5.1.3:** CDC metrics
  - Latency measurement
  - Throughput testing

### 5.2 Row-Level Access Control (RLAC)

#### Tasks
- [ ] **T5.2.1:** Row filtering via SQL
  - User A sees only region=North
  - User B sees only region=South

- [ ] **T5.2.2:** Column-level masking
  - Price column masked for analysts
  - Email column redacted for non-admins

- [ ] **T5.2.3:** Audit logging
  - Log all access attempts
  - Track who accessed what

### 5.3 BI Tool Integration

#### Tasks
- [ ] **T5.3.1:** Tableau connection
  - Direct SQL query
  - Performance testing

- [ ] **T5.3.2:** Power BI integration
  - Via Spark connector
  - Dashboard creation

- [ ] **T5.3.3:** Metadata catalog
  - Column descriptions
  - Lineage tracking

### Deliverables
```
✅ CDC pipeline setup
✅ RLAC implementation
✅ BI integration guide
✅ ITERATION_5_RESULTS.md
✅ Production readiness checklist
```

### Success Criteria
- ✅ CDC latency < 5 minutes
- ✅ RLAC não impacta performance
- ✅ BI tools retornam queries em < 30s
- ✅ 100% uptime SLA

---

## 📋 Cross-Iteration Concerns

### Monitoring (all iterations)
- Query execution time
- Memory utilization
- Storage growth
- Snapshot count

### Testing (all iterations)
- Unit tests para cada feature
- Integration tests
- Load tests (100K, 500K, 1M records)
- Regression tests

### Documentation (all iterations)
- Code comments
- Runbooks
- API documentation
- Troubleshooting guides

---

## 🎯 Success Metrics

### Iter. 1
- ✅ Baseline estabelecido
- ✅ 50K records em 1.91s

### Iter. 2
- ✅ Time Travel validado
- ✅ MERGE INTO funcional
- ✅ Schema evolution testado

### Iter. 3
- ✅ Compaction reduz files 50%
- ✅ Query performance igual/melhor
- ✅ Cleanup automático

### Iter. 4
- ✅ Security hardened
- ✅ Backup/restore < 1h
- ✅ Monitoring + alertas

### Iter. 5
- ✅ CDC < 5 min latency
- ✅ RLAC implementado
- ✅ BI integrado

### **Final Status:** 🏆 **PRODUCTION READY**

---

## 📅 Timeline Visual

```
Semana 1-2:   Iteration 1 [=====✅=====]
Semana 3-4:   Iteration 2         [=====🚀====]
Semana 5-6:   Iteration 3                [====⏳====]
Semana 7-8:   Iteration 4                        [===⏳===]
Semana 9-10:  Iteration 5                              [==⏳==]
```

---

## 🔗 File Dependencies

```
ITERATION_1_RESULTS.md
├── benchmark_results.json
├── test_simple_data_gen.py
└── test_simple_benchmark.py

ROADMAP_ITERACOES.md (este documento)
├── ITERATION_2_TASKS.md
│   ├── test_time_travel.py
│   ├── test_merge_into.py
│   └── test_schema_evolution.py
├── ITERATION_3_TASKS.md
│   ├── test_compaction.py
│   ├── test_snapshot_lifecycle.py
│   └── test_monitoring.py
├── ITERATION_4_TASKS.md
│   ├── security_hardening.md
│   ├── dr_procedure.md
│   └── monitoring_setup.md
└── ITERATION_5_TASKS.md
    ├── cdc_pipeline.md
    ├── rlac_implementation.md
    └── bi_integration.md
```

---

## 📞 Contact & Support

- **Lead:** DataLake Engineering Team
- **Repo:** https://github.com/gti-next/datalake-iceberg
- **Slack:** #datalake-engineering
- **Meetings:** Weekly sync (Tuesdays 10:00 AM BRT)

---

**Documento atualizado:** 2025-12-07 00:11:31 UTC
**Status Geral:** Iteration 1 ✅ | Iteration 2 🚀 | Production 🏆
**Próxima Review:** 2025-12-21 (Iter. 2 P1 checkpoint)
