# 📋 PHASE 1 EXECUTION - MANUAL GUIDE

**Status:** Servidor 192.168.4.33 não está acessível no momento  
**Data:** 7 de dezembro de 2025  
**Próxima ação:** Execute quando servidor estiver online

---

## ⚡ Se o Servidor Estiver Offline

Servidor pode estar:
- [ ] Em manutenção
- [ ] Desligado
- [ ] Fora da rede
- [ ] Com firewall bloqueando SSH

**Ação:** Verifique se servidor está ligado e conectado à rede

```powershell
# Assim que servidor estiver online, execute:
ping 192.168.4.33
```

---

## 🎯 CONTINUE COM ESTES PASSOS QUANDO SERVIDOR ESTIVER UP

### PASSO 1: Validar Pré-requisitos

```bash
# Teste SSH
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "echo 'SSH OK'"  # recomendado: usar chave canônica do projeto

# Teste Spark
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.33 "spark-submit --version | head -1"  # recomendado: usar chave canônica do projeto

# Teste MinIO
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "pgrep -f minio && echo 'MinIO OK'"  # recomendado: usar chave canônica do projeto

# Disco
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "df -h /home/datalake | grep datalake"  # recomendado: usar chave canônica do projeto
```

✅ **Todos devem retornar OK**

---

### PASSO 2: Upload dos 3 Scripts

```bash
# CD para diretório correto
cd c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2

# CDC Pipeline
scp -i scripts/key/ct_datalake_id_ed25519 `
    src\tests\test_cdc_pipeline.py `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# RLAC Implementation
scp -i scripts/key/ct_datalake_id_ed25519 `
    src\tests\test_rlac_implementation.py `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# BI Integration
scp -i scripts/key/ct_datalake_id_ed25519 `
    src\tests\test_bi_integration.py `
    datalake@192.168.4.37:/home/datalake/  # recomendado: usar chave canônica do projeto

# Verificar
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "ls -lh *.py"  # recomendado: usar chave canônica do projeto
```

✅ **Todos os 3 arquivos devem aparecer**

---

### PASSO 3: Executar Testes

```bash
# Test 1: CDC Pipeline
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G --executor-memory 4G \
  test_cdc_pipeline.py
EOF

# Test 2: RLAC Implementation
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G --executor-memory 4G \
  test_rlac_implementation.py
EOF

# Test 3: BI Integration
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 << 'EOF'  # recomendado: usar chave canônica do projeto
cd /home/datalake
spark-submit --master spark://192.168.4.33:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G --executor-memory 4G \
  test_bi_integration.py
EOF
```

⏱️ **5-15 minutos cada teste**

---

### PASSO 4: Coletar Resultados

```bash
# Copiar JSONs
scp -i scripts/key/ct_datalake_id_ed25519 \
    datalake@192.168.4.37:/home/datalake/*_results.json \
    artifacts/results/  # recomendado: usar chave canônica do projeto

# Verificar localmente
ls -lh artifacts/results/*_results.json
```

✅ **3 JSONs devem estar em artifacts/results/**

---

### PASSO 5: Validar Dados

```bash
# Verificar tabelas Hive
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.32 "hive -e 'SHOW TABLES;' 2>/dev/null"  # recomendado: usar chave canônica do projeto

# Verificar MinIO
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "mc ls datalake/ 2>/dev/null"  # recomendado: usar chave canônica do projeto

# Contar registros
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 \
  "spark-sql -e 'SELECT COUNT(*) FROM iceberg_table;'"  # recomendado: usar chave canônica do projeto
```

✅ **Dados devem estar intactos**

---

## 📊 Resultados Esperados

### CDC Pipeline
```json
{
  "latency_ms": 245.67,
  "correctness": 100.0,
  "status": "PASS"
}
```

### RLAC Implementation
```json
{
  "overhead_percent": 4.51,
  "enforcement": 100.0,
  "status": "PASS"
}
```

### BI Integration
```json
{
  "max_query_ms": 567.3,
  "superset.gti.local_render_ms": 1515.0,
  "status": "PASS"
}
```

---

## ✅ CHECKLIST FINAL

- [ ] Servidor online e acessível (ping OK)
- [ ] SSH connectivity validado
- [ ] Spark 4.0.1 rodando
- [ ] MinIO funcionando
- [ ] Disco tem >100GB livre
- [ ] 3 scripts uploaded
- [ ] CDC test PASSED (latency <245ms)
- [ ] RLAC test PASSED (overhead <5%)
- [ ] BI test PASSED (max query <567ms)
- [ ] 3 JSONs coletados em artifacts/results/
- [ ] Dados validados em produção
- [ ] Team sign-off obtido

**Se TUDO ✅:**
```
🟢 GO → PHASE 2: Team Training & Operations
```

---

## 🔄 Se Falhar: Rollback

```bash
# STOP tudo
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 "pkill -f spark-submit"  # recomendado: usar chave canônica do projeto

# Restaurar (se tiver backup)
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 \
  "cp -r /home/datalake/backups/pre_iter5/* /home/datalake/warehouse/"  # recomendado: usar chave canônica do projeto

# Reiniciar
ssh -i scripts/key/ct_datalake_id_ed25519 datalake@192.168.4.37 \
  "systemctl restart spark-master spark-worker hive-metastore"  # recomendado: usar chave canônica do projeto
```

Duration: ~5-10 minutos

---

## 📞 Próximas Ações

### Imediato (HOJE)
- [ ] Verificar se servidor 192.168.4.33 está online
- [ ] Confirmar acesso SSH funciona
- [ ] Preparar team para execução

### Assim que servidor estiver UP
- [ ] Execute PASSO 1-5 acima
- [ ] Coleta todos os resultados
- [ ] Decisão GO/NO-GO

### Se GO
- [ ] Marque PHASE 1 como ✅ COMPLETE
- [ ] Comece PHASE 2: Team Training (próxima semana)

### Se NO-GO
- [ ] Execute rollback
- [ ] Analise o que falhou
- [ ] Corrija e tente novamente

---

## 📚 Documentação Relacionada

- `START_PHASE_1_NOW.md` - Versão com comentários
- `PRODUCTION_DEPLOYMENT_CHECKLIST.md` - Checklist completo
- `PHASE_1_EXECUTION_START.md` - Guia detalhado
- `ITERATION_5_RESULTS.md` - Resultados esperados

---

**Status:** ⏳ Aguardando servidor online

Quando servidor estiver acessível, execute os passos acima!



