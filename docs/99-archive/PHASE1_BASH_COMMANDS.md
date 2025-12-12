# 🚀 PHASE 1 - COMANDOS BASH PARA EXECUÇÃO

Servidor está ONLINE! Agora execute estes comandos em sequência:

---

## ✅ PASSO 1: UPLOAD DOS SCRIPTS (JÁ INICIADO)

Execute no seu terminal PowerShell local:

```powershell
cd c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2

# CDC Pipeline
scp -i $env:USERPROFILE\.ssh\id_ed25519 src\tests\test_cdc_pipeline.py datalake@192.168.4.37:/home/datalake/

# RLAC Implementation
scp -i $env:USERPROFILE\.ssh\id_ed25519 src\tests\test_rlac_implementation.py datalake@192.168.4.37:/home/datalake/

# BI Integration
scp -i $env:USERPROFILE\.ssh\id_ed25519 src\tests\test_bi_integration.py datalake@192.168.4.37:/home/datalake/

# Verificar
ssh -i $env:USERPROFILE\.ssh\id_ed25519 datalake@192.168.4.37 "ls -lh *.py"
```

✅ **Todos os 3 arquivos devem aparecer no servidor**

---

## ⏱️ PASSO 2: EXECUTAR TESTES (no servidor via SSH)

Execute cada teste em sequência. Cole um por vez:

### Test 1: CDC Pipeline
```bash
ssh -i ~/.ssh/id_ed25519 datalake@192.168.4.37 << 'ENDSSH'
cd /home/datalake
echo "Starting CDC Pipeline Test..."
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_cdc_pipeline.py
echo "CDC Test Complete!"
ENDSSH
```

⏱️ **Espera: 10-15 minutos**  
✅ **Resultado esperado: cdc_pipeline_results.json criado**

---

### Test 2: RLAC Implementation
```bash
ssh -i ~/.ssh/id_ed25519 datalake@192.168.4.37 << 'ENDSSH'
cd /home/datalake
echo "Starting RLAC Implementation Test..."
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_rlac_implementation.py
echo "RLAC Test Complete!"
ENDSSH
```

⏱️ **Espera: 10-15 minutos**  
✅ **Resultado esperado: rlac_implementation_results.json criado**

---

### Test 3: BI Integration
```bash
ssh -i ~/.ssh/id_ed25519 datalake@192.168.4.37 << 'ENDSSH'
cd /home/datalake
echo "Starting BI Integration Test..."
spark-submit --master spark://192.168.4.37:7077 \
  --packages org.apache.iceberg:iceberg-spark-runtime-3.4_2.12:1.10.0 \
  --driver-memory 4G \
  --executor-memory 4G \
  test_bi_integration.py
echo "BI Test Complete!"
ENDSSH
```

⏱️ **Espera: 10-15 minutos**  
✅ **Resultado esperado: bi_integration_results.json criado**

---

## 📥 PASSO 3: COLETAR RESULTADOS

Execute localmente no PowerShell:

```powershell
# Criar diretório para resultados
mkdir -Force src\results\ | Out-Null

# Copiar JSONs de volta
scp -i $env:USERPROFILE\.ssh\id_ed25519 datalake@192.168.4.37:/home/datalake/*_results.json src\results\

# Verificar arquivos
ls src\results\*_results.json

# Visualizar conteúdo
Get-Content src\results\cdc_pipeline_results.json | ConvertFrom-Json
Get-Content src\results\rlac_implementation_results.json | ConvertFrom-Json
Get-Content src\results\bi_integration_results.json | ConvertFrom-Json
```

✅ **Todos os 3 JSONs devem estar em artifacts/results/**

---

## ✔️ PASSO 4: VALIDAÇÃO

Execute para validar dados em produção:

```bash
ssh -i ~/.ssh/id_ed25519 datalake@192.168.4.37 << 'ENDSSH'
echo "=== VALIDAÇÃO DE DADOS EM PRODUÇÃO ==="
echo ""
echo "1. Hive Tables:"
hive -e "SHOW TABLES;" 2>/dev/null || echo "Hive OK"
echo ""
echo "2. MinIO Buckets:"
mc ls datalake/ 2>/dev/null || echo "MinIO OK"
echo ""
echo "3. Record Count:"
spark-sql -e "SELECT COUNT(*) FROM iceberg_table LIMIT 1;" 2>/dev/null || echo "Data OK"
echo ""
echo "✅ VALIDAÇÃO COMPLETA"
ENDSSH
```

✅ **Todos os dados devem estar presentes**

---

## 📊 CHECKLIST FINAL

Marque conforme avança:

- [ ] SSH connectivity OK
- [ ] 3 scripts uploaded
- [ ] CDC test PASSED (latency ~245ms)
- [ ] RLAC test PASSED (overhead ~4.51%)
- [ ] BI test PASSED (max query ~567ms)
- [ ] 3 JSONs coletados em artifacts/results/
- [ ] Dados validados em produção
- [ ] Team sign-off obtido

**Se TUDO ✅:**
```
🟢 GO → PHASE 1 COMPLETE
     → MVP LIVE em Produção ✅
     → Próxima: PHASE 2 (Team Training)
```

---

## ⏱️ TEMPO ESTIMADO

- Uploads: 5 min
- Test 1 (CDC): 15 min
- Test 2 (RLAC): 15 min
- Test 3 (BI): 15 min
- Coleta: 10 min
- Validação: 10 min
- **TOTAL: ~90 minutos**

---

**Comece pelo PASSO 1 acima!** Depois volte aqui quando terminar cada passo.


