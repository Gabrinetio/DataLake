# ✅ PRODUCTION DEPLOYMENT CHECKLIST

**Objetivo:** Guia passo-a-passo para deploy de Iteração 5 em produção  
**Data:** 7 de dezembro de 2025  
**Status:** ⏳ Pronto para execução

---

## 📋 PRÉ-DEPLOYMENT (24 horas antes)

### Infrastructure Validation
- [ ] Servidor de produção acessível via SSH
- [ ] Spark cluster up and running
- [ ] MinIO buckets criados e funcionais
- [ ] Hive Metastore conectado
- [ ] Network connectivity validado (latency < 50ms)

### Data Preparation
- [ ] Backup de dados atuais feito
- [ ] Backup local em /home/datalake/backups/
- [ ] Backup remoto confirmado
- [ ] Data size verified (expectativa 50K+ registros)

### Documentation Review
- [ ] Leu `../30-iterations/results/ITERATION_5_RESULTS.md`
- [ ] Entendeu os 3 features (CDC, RLAC, BI)
- [ ] Anotou targets de performance
- [ ] Preparou rollback plan

### Team Notification
- [ ] Avisou stakeholders sobre deployment
- [ ] Agendou team standup pré-deployment
- [ ] Preparou escalation contacts
- [ ] Setup communication channel (Slack/Teams)

---

## 🚀 DEPLOYMENT (Execution)

### Phase 1: Upload Scripts (30 minutos)

```bash
# 1. Copy CDC script
scp -i /keys/id_ed25519 src/tests/test_cdc_pipeline.py \
    datalake@192.168.4.37:/home/datalake/

# 2. Copy RLAC script
scp -i /keys/id_ed25519 src/tests/test_rlac_implementation.py \
    datalake@192.168.4.37:/home/datalake/

# 3. Copy BI script
scp -i /keys/id_ed25519 src/tests/test_bi_integration.py \
    datalake@192.168.4.37:/home/datalake/
```

**Checklist:**
- [ ] CDC script transferred (350 linhas)
- [ ] RLAC script transferred (340 linhas)
- [ ] BI script transferred (360 linhas)
- [ ] Verificou permissões (755)

### Phase 2: Pre-execution Tests (30 minutos)

```bash
# Test connectivity
ssh -i /keys/id_ed25519 datalake@192.168.4.37 'spark-shell --version'

# Verify data availability
ssh -i /keys/id_ed25519 datalake@192.168.4.37 'ls -lh /home/datalake/warehouse/'

# Check MinIO access
ssh -i /keys/id_ed25519 datalake@192.168.4.37 'minio -v'
```

**Checklist:**
- [ ] SSH connectivity OK
- [ ] Spark version confirmed (4.0.1)
- [ ] Warehouse directory accessible
- [ ] MinIO running

### Phase 3: Execute CDC Pipeline (20 minutos)

```bash
# Execute CDC test
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'cd /home/datalake && \
     spark-submit test_cdc_pipeline.py 2>&1 | tee cdc_execution.log'
```

**Validation:**
- [ ] Script iniciou sem erros
- [ ] Setup phase completou
- [ ] Changes aplicadas corretamente
- [ ] Delta capture funcionou
- [ ] Latency < 5 minutos ✅
- [ ] Resultados salvos em /tmp/cdc_pipeline_results.json

**Target Metrics:**
- ✅ CDC Latency: 245.67ms (expect ~200-300ms)
- ✅ Delta Correctness: 100%
- ✅ Data integrity: Verified

### Phase 4: Execute RLAC Implementation (20 minutos)

```bash
# Execute RLAC test
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'cd /home/datalake && \
     spark-submit test_rlac_implementation.py 2>&1 | tee rlac_execution.log'
```

**Validation:**
- [ ] Script iniciou sem erros
- [ ] Users and departments criados
- [ ] RLAC views criadas
- [ ] Access control testado (5 users)
- [ ] Overhead < 5% ✅
- [ ] Zero data leakage confirmed

**Target Metrics:**
- ✅ Performance Overhead: 4.51% (expect < 5%)
- ✅ Enforcement: 100%
- ✅ Data protection: Perfect

### Phase 5: Execute BI Integration (20 minutos)

```bash
# Execute BI test
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'cd /home/datalake && \
     spark-submit test_bi_integration.py 2>&1 | tee bi_execution.log'
```

**Validation:**
- [ ] Script iniciou sem erros
- [ ] BI tables criadas
- [ ] 5 queries executadas
- [ ] All queries < 30s ✅
- [ ] superset.gti.local simulation completou
- [ ] All charts < 2s each

**Target Metrics:**
- ✅ Max Query Latency: 567.3ms (expect 400-600ms)
- ✅ Avg Query Latency: 378.6ms
- ✅ superset.gti.local: 1.515s (4 charts)

### Phase 6: Results Collection (15 minutos)

```bash
# Download results
scp -i /keys/id_ed25519 \
    datalake@192.168.4.37:/tmp/*_results.json \
    ./artifacts/results/

# Verify results
ls -lh artifacts/results/*_results.json
```

**Checklist:**
- [ ] cdc_pipeline_results.json downloaded
- [ ] rlac_implementation_results.json downloaded
- [ ] bi_integration_results.json downloaded
- [ ] All JSON files valid (run `jq . file.json`)

---

## ✅ POST-DEPLOYMENT VALIDATION

### Data Integrity Checks (1 hora)

```bash
# Verify data hasn't changed unexpectedly
# Expected: 50,007 records (50K + 10 insert - 3 delete + 5 update)

ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'spark-sql -e "SELECT COUNT(*) FROM vendas_live;"'
```

- [ ] Record count matches expectation
- [ ] No data corruption detected
- [ ] Schema unchanged
- [ ] Partitions intact

### Performance Baseline (30 minutos)

```bash
# Run benchmark query
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'spark-sql -e "SELECT COUNT(*), AVG(amount) FROM vendas_live;" --verbose'
```

- [ ] Query latency captured
- [ ] Baseline established
- [ ] Results match previous runs

### Security Validation (30 minutos)

```bash
# Verify RLAC enforcement
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'spark-sql -e "SELECT * FROM vendas_sales LIMIT 5;"'
```

- [ ] Sales users can see data
- [ ] Finance users blocked from Sales view
- [ ] HR users blocked appropriately
- [ ] Audit logs created

---

## 📊 MONITORING SETUP (1 hora)

### Prometheus Configuration
- [ ] Prometheus scrape config updated
- [ ] Spark metrics exposed
- [ ] MinIO metrics available
- [ ] Collection started

### Grafana superset.gti.locals
- [ ] Import DataLake superset.gti.local
- [ ] Setup query performance graph
- [ ] Setup CDC latency graph
- [ ] Setup BI query times
- [ ] Verify data flowing in

### Alert Configuration
- [ ] CDC latency > 500ms → Warning
- [ ] Query latency > 2s → Alert
- [ ] Cluster health check
- [ ] Data validation checks
- [ ] Alerts sent to on-call team

---

## 🚨 ROLLBACK PLAN

If anything goes wrong, execute rollback:

### Option 1: Quick Rollback (< 10 min)
```bash
# Restore from backup
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'bash /home/datalake/backups/restore_latest.sh'

# Verify restoration
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'spark-sql -e "SELECT COUNT(*) FROM vendas_live;"'
```

**Conditions to trigger:**
- [ ] CDC pipeline crashes
- [ ] RLAC breaks data access
- [ ] Query latency > 10s
- [ ] Data corruption detected

### Option 2: Full Revert (< 30 min)
```bash
# Stop all services
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'systemctl stop spark-master spark-worker hive-metastore'

# Restore from daily backup
# (process depends on backup strategy)

# Restart services
ssh -i /keys/id_ed25519 datalake@192.168.4.37 \
    'systemctl start spark-master spark-worker hive-metastore'
```

**Conditions to trigger:**
- [ ] Multiple feature failures
- [ ] Infrastructure instability
- [ ] Unable to reach performance targets

---

## 📋 SIGN-OFF CHECKLIST

### Pre-Production Approval
- [ ] Infrastructure Lead: _________________ Date: ___
- [ ] Operations Manager: ________________ Date: ___
- [ ] Security Officer: __________________ Date: ___
- [ ] Project Lead: ______________________ Date: ___

### Deployment Execution
- [ ] Deployment conducted by: _________________
- [ ] Date/Time started: ________________________
- [ ] Date/Time completed: _____________________
- [ ] Any issues encountered: Yes / No

### Post-Deployment Validation
- [ ] All metrics within targets: Yes / No
- [ ] No data loss: Yes / No
- [ ] Performance acceptable: Yes / No
- [ ] Monitoring active: Yes / No
- [ ] Team trained and ready: Yes / No

### Final Approval
- [ ] Ready for production use: Yes / No
- [ ] Approved by: ____________________________
- [ ] Date: __________________________________

---

## 📞 CONTACTS & ESCALATION

### On-Call During Deployment
```
Lead:         [Name] - [Phone]
Backup:       [Name] - [Phone]
Infrastructure: [Name] - [Phone]
Database:     [Name] - [Phone]
```

### Critical Issues Escalation
```
If CDC fails:       Contact [Infrastructure]
If data loss:       Activate RTO procedures
If performance bad: Trigger rollback
If RLAC broken:     Call Security team
```

---

## ⏱️ TIMELINE ESTIMATE

```
Total Time: ~3.5 hours

Pre-deployment:     1 hour  ✅
Phase 1 (Upload):   30 min  ✅
Phase 2 (Tests):    30 min  ✅
Phase 3 (CDC):      20 min  ✅
Phase 4 (RLAC):     20 min  ✅
Phase 5 (BI):       20 min  ✅
Phase 6 (Collect):  15 min  ✅
Validation:         1 hour  ✅
Monitoring:         1 hour  ✅
Buffer/Issues:      30 min  ⚠️

Total: 3-4 hours (with buffer)
```

---

## 📚 Related Documents

- 📄 `../30-iterations/results/ITERATION_5_RESULTS.md` - What's being deployed
- 📄 `docs/CONTEXT.md` - Infrastructure details
- 📄 `docs/Projeto.md` - Architecture reference
- 📄 `../30-iterations/results/PROJETO_COMPLETO_90_PORCENTO.md` - Status overview

---

## 🎯 Success Criteria

After deployment, validate:

✅ **CDC Pipeline**
- Latency < 5 min (actual: ~245ms)
- Correctness 100%
- No data loss

✅ **RLAC Implementation**
- Overhead < 5% (actual: ~4.51%)
- Access control 100%
- Zero data leakage

✅ **BI Integration**
- Query latency < 30s (actual: ~567ms max)
- superset.gti.local < 2s (actual: ~1.5s)
- 18/18 tests passing

✅ **Operations**
- Monitoring active
- Alerts configured
- Team trained

---

**Deployment Date:** [To be filled]  
**Completed By:** [To be filled]  
**Validation Date:** [To be filled]  

🚀 **Ready to deploy to production!**





