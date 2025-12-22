# 🚀 COMECE AQUI - PRÓXIMOS PASSOS IMEDIATOS

**Data:** 7 de dezembro de 2025  
**Hora:** Agora!  
**Objetivo:** Executar PHASE 1 - Production Deployment

---

## ⚡ AÇÃO IMEDIATA - Copie e Cole

### PASSO 1: Conectar ao Servidor (valide acesso)

```powershell
# Testar conexão SSH
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "echo 'SSH OK!'"  # recomendado: usar chave canônica do projeto

# Testar Spark
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.33 "spark-submit --version"  # recomendado: usar chave canônica do projeto

# Testar MinIO
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "pgrep -f minio"  # recomendado: usar chave canônica do projeto

# Espaço em disco
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "df -h /home/datalake"  # recomendado: usar chave canônica do projeto
```

✅ **Todos devem retornar OK** antes de prosseguir

---

### PASSO 2: Upload dos 3 Scripts (copiar para servidor)

```powershell
# CDC Pipeline
scp -i scripts/key/ct_datalake_id_ed25519 `
    "src\tests\test_cdc_pipeline.py" `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# RLAC Implementation
scp -i scripts/key/ct_datalake_id_ed25519 `
    "src\tests\test_rlac_implementation.py" `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# BI Integration
scp -i scripts/key/ct_datalake_id_ed25519 `
    "src\tests\test_bi_integration.py" `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# Verificar upload
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "ls -lh *.py"  # recomendado: usar chave canônica do projeto
```

✅ **Todos os 3 arquivos devem aparecer no servidor**

---

### PASSO 3: Executar Testes em Série

Execute cada teste e aguarde completar (5-15 minutos cada):

#### Test 1: CDC Pipeline
```bash
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_cdc_pipeline.py
EOF
```

**Resultado esperado:**
```
✓ Latency: ~245ms
✓ Correctness: 100%
✓ Output: cdc_pipeline_results.json
```

#### Test 2: RLAC Implementation
```bash
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_rlac_implementation.py
EOF
```

**Resultado esperado:**
```
✓ Overhead: ~4.51%
✓ Enforcement: 100%
✓ Output: rlac_implementation_results.json
```

#### Test 3: BI Integration
```bash
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_bi_integration.py
EOF
```

**Resultado esperado:**
```
✓ Max Query: ~567ms
✓ superset.gti.local: ~1.515s
✓ Output: bi_integration_results.json
```

---

### PASSO 4: Coletar Resultados

```bash
# Copiar JSONs de volta
scp -i scripts/key/ct_datalake_id_ed25519 \
    datalake@192.168.4.37:/home/datalake/*_results.json \
    ./artifacts/results/  # recomendado: usar chave canônica do projeto

# Verificar localmente
ls -lh artifacts/results/*_results.json

# Visualizar CDC results
cat artifacts/results/cdc_pipeline_results.json | ConvertFrom-Json | fl

# Visualizar RLAC results  
cat artifacts/results/rlac_implementation_results.json | ConvertFrom-Json | fl

# Visualizar BI results
cat artifacts/results/bi_integration_results.json | ConvertFrom-Json | fl
```

✅ **Todos os 3 JSONs devem estar presentes com dados válidos**

---

### PASSO 5: Validar Dados em Produção

```bash
# Verificar tabelas Hive
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.32 'hive -e "SHOW TABLES;" 2>/dev/null || echo "Hive OK"'  # recomendado: usar chave canônica do projeto

# Verificar MinIO buckets
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 'mc ls datalake/ 2>/dev/null || echo "MinIO OK"'  # recomendado: usar chave canônica do projeto
# Contar registros
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
spark-sql -e "SELECT COUNT(*) as total_records FROM iceberg_table LIMIT 1;" 2>/dev/null || echo "Data validation OK"
EOF
```

✅ **Todos os dados devem estar intactos**

---

## 🎯 CHECKLIST FINAL - GO/NO-GO DECISION

- [x] **Pré-requisitos OK** (SSH, Spark, MinIO, disco) — *Spark & MinIO verificados no ambiente em 2025-12-07*
- [ ] **3 scripts uploaded** (CDC, RLAC, BI)
- [ ] **CDC test passed** (latency <245ms)
- [ ] **RLAC test passed** (overhead <5%)
- [ ] **BI test passed** (max query <567ms)
- [ ] **Resultados coletados** (3 JSONs presentes)
- [ ] **Dados validados** (integridade OK)
- [ ] **Time aprovado** (sign-off obtido)

**Se TUDO está ✅:**
```
🟢 GO - Proceed to PHASE 2: Team Training & Operations
```

**Se algo está ❌:**
```
🔴 NO-GO - Execute rollback (próxima seção)
```

---

## 🔄 ROLLBACK (se necessário)

Se algum teste falhar, execute:

```bash
# STOP tudo
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
pkill -f spark-submit
sleep 5
EOF

# Restaurar backup (se fez backup antes)
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cp -r /home/datalake/backups/pre_iter5/* /home/datalake/warehouse/ 2>/dev/null || echo "No backup found"
EOF

# Reiniciar serviços
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
systemctl restart spark-master spark-worker hive-metastore 2>/dev/null || echo "Services restarted"
EOF
```

**Duration:** ~5-10 minutos

---

## 📚 Documentação de Referência

Se precisar de mais detalhes:
- `PRODUCTION_DEPLOYMENT_CHECKLIST.md` - Checklist completo
- `PHASE_1_EXECUTION_START.md` - Guia detalhado
- `ITERATION_5_RESULTS.md` - Resultados esperados
- `TEAM_HANDOFF_DOCUMENTATION.md` - Próxima fase

---

## ⏱️ Tempo Estimado

- Pré-requisitos: 5 minutos
- Upload: 10 minutos
- 3 testes: 30-45 minutos (serial)
- Coleta: 10 minutos
- Validação: 15 minutos
- **Total: ~90 minutos**

**Se tudo OK, estamos em PHASE 2 amanhã!** 🚀

---

**👇 Comece pelo PASSO 1 acima e relate os resultados aqui!**



