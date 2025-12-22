# 🚀 PHASE 1 - EXECUTION PLAN
## Production Deployment - Week 1-2 (8-21 december)

**Data:** 7 de dezembro de 2025  
**Status:** ⏳ Iniciando execução AGORA  
**Meta:** MVP LIVE em Produção

---

## 📋 CHECKLIST SIMPLIFICADO - COMECE AQUI

### ✅ Pré-requisitos (Validar AGORA)

```powershell
# 1. Verificar conexão com servidor
ssh -i C:\Users\Gabriel Santana\.ssh\id_ed25519 datalake@192.168.4.37 "echo 'Connection OK'"

# 2. Verificar Spark está rodando
ssh -i C:\Users\Gabriel Santana\.ssh\id_ed25519 datalake@192.168.4.37 "spark-submit --version"

# 3. Verificar MinIO está rodando
ssh -i C:\Users\Gabriel Santana\.ssh\id_ed25519 datalake@192.168.4.37 "pgrep -f minio"

# 4. Verificar espaço em disco
ssh -i C:\Users\Gabriel Santana\.ssh\id_ed25519 datalake@192.168.4.37 "df -h /home/datalake"
```

**Status:**
- [ ] Connection OK
- [ ] Spark running
- [ ] MinIO running
- [ ] Disk space OK (>100GB free)

---

### 📤 STEP 1: Upload Scripts (30 min)

Copiar os 3 scripts Iter5 para servidor:

```powershell
# Copiar CDC pipeline
scp -i C:\Users\Gabriel Santana\.ssh\id_ed25519 `
    src\tests\test_cdc_pipeline.py `
    datalake@192.168.4.37:/home/datalake/

# Copiar RLAC implementation
scp -i C:\Users\Gabriel Santana\.ssh\id_ed25519 `
    src\tests\test_rlac_implementation.py `
    datalake@192.168.4.37:/home/datalake/

# Copiar BI integration
scp -i C:\Users\Gabriel Santana\.ssh\id_ed25519 `
    src\tests\test_bi_integration.py `
    datalake@192.168.4.37:/home/datalake/

# Verificar upload
ssh -i C:\Users\Gabriel Santana\.ssh\id_ed25519 datalake@192.168.4.37 "ls -lh *.py"
```

**Status:**
- [ ] CDC uploaded
- [ ] RLAC uploaded
- [ ] BI uploaded
- [ ] All files verified

---

### ⚙️ STEP 2: Execute Tests (1h cada)

Executar os 3 testes em produção:

```bash
# TEST 1: CDC Pipeline (10-15 min)
cd /home/datalake
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_cdc_pipeline.py

# TEST 2: RLAC Implementation (10-15 min)
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_rlac_implementation.py

# TEST 3: BI Integration (10-15 min)
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_bi_integration.py
```

**Expected Results:**
- [ ] CDC latency: ~245ms (✓ < 5min target)
- [ ] RLAC overhead: ~4.51% (✓ < 5% target)
- [ ] BI max query: ~567ms (✓ < 30s target)

---

### 📊 STEP 3: Collect Results (30 min)

Depois de executar os 3 testes, coletar os JSONs:

```bash
# Copy result files back
scp -i /keys/id_ed25519 datalake@192.168.4.37:/home/datalake/*_results.json .

# Verify results
ls -lh *_results.json
cat cdc_pipeline_results.json | jq .
cat rlac_implementation_results.json | jq .
cat bi_integration_results.json | jq .
```

**Status:**
- [ ] CDC results collected
- [ ] RLAC results collected
- [ ] BI results collected
- [ ] All validations passed

---

### ✅ STEP 4: Validate Production Data (30 min)

Validar que dados estão corretos em produção:

```bash
# Check Hive tables
ssh -i /keys/id_ed25519 datalake@192.168.4.32 'hive -e "SHOW TABLES;"'

# Check MinIO buckets
ssh -i /keys/id_ed25519 datalake@192.168.4.37 'mc ls datalake/raw'

# Check record counts
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
  'spark-sql -e "SELECT COUNT(*) FROM iceberg_table;"'

# Verify data integrity
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
  'spark-sql -e "SELECT * FROM iceberg_table LIMIT 5;"'
```

**Status:**
- [ ] Hive tables accessible
- [ ] MinIO buckets readable
- [ ] Record counts match expected
- [ ] Data sample looks correct

---

### 🎯 STEP 5: Go/No-Go Decision (30 min)

Reviewar resultados e fazer decisão final:

**Check Results:**
```
CDC Pipeline:
✓ Latency: 245.67ms (49x melhor que target)
✓ Correctness: 100%
✓ Latency Stability: ±15ms

RLAC Implementation:
✓ Overhead: 4.51% (within target)
✓ Enforcement: 100%
✓ Performance: Acceptable

BI Integration:
✓ Max Query: 567.3ms (53x melhor que target)
✓ superset.gti.local: 1.515s (within SLA)
✓ Responsiveness: Good
```

**Sign-off Checklist:**
- [ ] All 3 features working
- [ ] All performance targets MET
- [ ] Data integrity validated
- [ ] Team sign-off obtained
- [ ] Rollback plan ready

**GO/NO-GO DECISION:**
- [ ] **GO** - Proceed to Phase 2
- [ ] **NO-GO** - Rollback (ver seção abaixo)

---

## ⚙️ ROLLBACK (se necessário)

Se algum teste falhar, rollback é rápido:

```bash
# 1. Stop Spark jobs
ssh -i /keys/id_ed25519 datalake@192.168.4.37 'pkill -f spark-submit'

# 2. Restore from backup
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
  'cp -r /home/datalake/backups/pre_iter5/* /home/datalake/warehouse/'

# 3. Restart services
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
  'systemctl restart spark-master spark-worker hive-metastore'

# 4. Verify restored state
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
  'spark-sql -e "SELECT COUNT(*) FROM iceberg_table;"'
```

**Rollback Duration:** ~5-10 minutos

---

## 📅 TIMELINE

```
Hoje (7 dez):
├─ 14:00 - Validar pré-requisitos
├─ 14:30 - Upload scripts (30 min)
└─ 15:00 - Ready for testing

Amanhã (8 dez) - TEST DAY:
├─ 09:00 - CDC Pipeline test (15 min)
├─ 09:30 - RLAC test (15 min)
├─ 10:00 - BI test (15 min)
├─ 10:30 - Results collection (15 min)
├─ 11:00 - Data validation (30 min)
└─ 11:30 - GO/NO-GO decision

Semana seguinte:
├─ Deploy para produção oficial
├─ 24/7 monitoring start
└─ PHASE 2: Team Training
```

---

## 🎯 Success Criteria

✅ **MVP LIVE** when:
1. All 3 Iter5 features passing production tests
2. All performance targets exceeded
3. Data integrity validated
4. Team signed off
5. Rollback plan confirmed

**Current Status:** 90% → 100% (production ready!)

---

## ⚡ Quick Links

- [Full Deployment Checklist](../20-operations/checklists/PRODUCTION_DEPLOYMENT_CHECKLIST.md)
- [Iter 5 Results](../ARQUIVO/ITERATION_5_RESULTS.md)
- [Team Handoff](TEAM_HANDOFF_DOCUMENTATION.md)
- [Executive Summary](../00-overview/EXECUTIVE_SUMMARY.md)

---

**Let's go! 🚀**




