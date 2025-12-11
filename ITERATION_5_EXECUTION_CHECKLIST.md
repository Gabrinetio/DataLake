# ✅ ITERAÇÃO 5 - Checklist de Execução

**Data de Início:** 7 de dezembro de 2025  
**Status:** 🚀 Pronto para Começar  
**Estimativa:** ~2 horas  
**Meta:** 90% do projeto completo

---

## 📋 Pre-Execution Checklist

Antes de começar, verifique:

- [ ] Server 192.168.4.37 acessível via SSH
- [ ] Spark 4.0.1 rodando normalmente
- [ ] Python 3.11.2 disponível
- [ ] Todos os scripts anteriores passando (Iter 1-4)
- [ ] Pasta `/home/datalake/warehouse` acessível
- [ ] ED25519 SSH key funcionando

---

## 🚀 Execução em 3 Fases

### FASE A: CDC Pipeline (30 min)

**Local:** Seu computador  
**Comandos:**

```bash
# 1. Copiar script para servidor
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    src/tests/test_cdc_pipeline.py \
    datalake@192.168.4.37:/home/datalake/

# 2. Executar via SSH
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "spark-submit /home/datalake/test_cdc_pipeline.py 2>&1" | tee test_cdc.log

# 3. Capturar últimas 50 linhas
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "tail -50 /tmp/cdc_pipeline_results.json"

# 4. Copiar resultado para local
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37:/tmp/cdc_pipeline_results.json \
    src/results/
```

**Critérios de Sucesso:**
- ✅ Tabela vendas_live criada (50K records)
- ✅ Mudanças capturadas (INSERT 10, UPDATE 5, DELETE 3)
- ✅ Delta correctness 100%
- ✅ Latency < 5 min

**Resultado esperado:** `/tmp/cdc_pipeline_results.json`

---

### FASE B: RLAC Implementation (25 min)

**Local:** Seu computador  
**Comandos:**

```bash
# 1. Copiar script para servidor
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    src/tests/test_rlac_implementation.py \
    datalake@192.168.4.37:/home/datalake/

# 2. Executar via SSH
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "spark-submit /home/datalake/test_rlac_implementation.py 2>&1" | tee test_rlac.log

# 3. Capturar últimas 50 linhas
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "tail -50 /tmp/rlac_implementation_results.json"

# 4. Copiar resultado para local
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37:/tmp/rlac_implementation_results.json \
    src/results/
```

**Critérios de Sucesso:**
- ✅ Tabela com departamentos criada (300 records)
- ✅ Views RLAC criadas (4 views)
- ✅ Acesso granular validado por usuário
- ✅ Overhead < 5%

**Resultado esperado:** `/tmp/rlac_implementation_results.json`

---

### FASE C: BI Integration (25 min)

**Local:** Seu computador  
**Comandos:**

```bash
# 1. Copiar script para servidor
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    src/tests/test_bi_integration.py \
    datalake@192.168.4.37:/home/datalake/

# 2. Executar via SSH
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "spark-submit /home/datalake/test_bi_integration.py 2>&1" | tee test_bi.log

# 3. Capturar últimas 50 linhas
ssh -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37 \
    "tail -50 /tmp/bi_integration_results.json"

# 4. Copiar resultado para local
scp -i "C:\Users\Gabriel Santana\.ssh\id_ed25519" \
    datalake@192.168.4.37:/tmp/bi_integration_results.json \
    src/results/
```

**Critérios de Sucesso:**
- ✅ Tabelas BI criadas (50K records)
- ✅ 5 queries executadas com sucesso
- ✅ superset.gti.local simulado (4 charts)
- ✅ Latency < 30s por query

**Resultado esperado:** `/tmp/bi_integration_results.json`

---

## 📊 Pós-Execução

Após executar os 3 scripts:

### 1. Verificar Resultados

```bash
# Ver estrutura de resultados
ls -lah src/results/

# Verificar JSONs
cat src/results/cdc_pipeline_results.json | python -m json.tool
cat src/results/rlac_implementation_results.json | python -m json.tool
cat src/results/bi_integration_results.json | python -m json.tool
```

### 2. Documentar Resultados

Criar arquivo: `docs/ITERATION_5_RESULTS.md`

```markdown
# ITERATION 5 - RESULTADOS FINAIS

## Resumo
- CDC: ✅ Passou
- RLAC: ✅ Passou
- BI: ✅ Passou

## Métricas

### CDC Pipeline
- Latency: X ms
- Correctness: 100%
- Records processados: 50K + 10 + 5 deletes

### RLAC Implementation
- Views criadas: 4
- Usuarios testados: 5
- Overhead: X%

### BI Integration
- Queries executadas: 5
- superset.gti.local charts: 4
- Query latency máx: X ms

## Conclusões
...
```

### 3. Atualizar Índice

Editar `docs/INDICE_DOCUMENTACAO.md`:

```markdown
### ✅ Iteração 5 - CDC + RLAC + BI
- **Status:** Completa (100%)
- **Referência:** [ITERATION_5_RESULTS.md](../ARQUIVO/ITERATION_5_RESULTS.md)
- **Métricas:** CDC latency <5min, RLAC <5% overhead, BI <30s
```

---

## ⚠️ Troubleshooting

### Se CDC falhar:
- Verificar se Iceberg funciona: `SELECT * FROM vendas_small.snapshots LIMIT 1`
- Verificar espaço em disco: `df -h /home/datalake/`
- Verificar permissões: `ls -la /home/datalake/warehouse/`

### Se RLAC falhar:
- Verificar se views são criadas: `SHOW VIEWS;`
- Testar filtro manualmente: `SELECT COUNT(*) FROM vendas_rlac WHERE department='Sales'`

### Se BI falhar:
- Verificar particionamento: `SELECT * FROM vendas_bi.partitions;`
- Testar query agregada: `SELECT categoria, COUNT(*) FROM vendas_bi GROUP BY categoria;`

---

## 🎯 Sucesso Total = Todos os 3 scripts passarem

```
✅ test_cdc_pipeline.py → SUCCESS
✅ test_rlac_implementation.py → SUCCESS
✅ test_bi_integration.py → SUCCESS
═════════════════════════════════════
✅ ITERAÇÃO 5 COMPLETA - 90% PROJETO
```

---

## 📝 Checklist Final

Após tudo executado com sucesso:

- [ ] 3 JSONs resultados salvos em `src/results/`
- [ ] `ITERATION_5_RESULTS.md` criado
- [ ] `docs/INDICE_DOCUMENTACAO.md` atualizado
- [ ] Status em `docs/CONTEXT.md` atualizado para 90%
- [ ] Todos os tests passando (15 + 3 = 18 testes)
- [ ] Documentação completa e atualizada

---

## ⏱️ Timeline

| Fase | Duração | Status |
|------|---------|--------|
| CDC Pipeline | 30 min | ⏳ |
| RLAC Implementation | 25 min | ⏳ |
| BI Integration | 25 min | ⏳ |
| Documentação | 15 min | ⏳ |
| **TOTAL** | **~1:35h** | **⏳** |

---

**Versão:** 1.0  
**Criado:** 7 de dezembro de 2025  
**Status:** Pronto para execução 🚀



