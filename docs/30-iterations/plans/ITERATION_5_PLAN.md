# 🚀 ITERATION 5: Change Data Capture + Row-Level Access Control + BI Integration

**Data:** 7 de dezembro de 2025  
**Status:** Planejada ⏳  
**Estimativa:** ~2 horas  
**Meta:** 90% projeto completo  

---

## 📋 Resumo Executivo

Iteração 5 implementa três funcionalidades críticas para DataLake em produção:

1. **CDC (Change Data Capture)** - Capturar mudanças incrementais
2. **RLAC (Row-Level Access Control)** - Controle granular de acesso
3. **BI Integration** - Integração com ferramentas de BI (Superset/Tableau)

**Resultado esperado:** Sistema completo, pronto para produção, com 90% de cobertura.

---

## ✅ Pré-requisitos

- ✅ Iteração 1: Data generation e benchmark (50K records)
- ✅ Iteração 2: Time travel e MERGE INTO (snapshots funcionais)
- ✅ Iteração 3: Compaction e monitoring (0.703s avg queries)
- ✅ Iteração 4: Backup/restore, DR, security (23 políticas)
- ✅ Server 192.168.4.33 acessível
- ✅ Spark 4.0.1 funcionando
- ✅ Data em `/home/datalake/data/vendas_small`

---

## 🎯 Objetivos Específicos

### 1️⃣ CDC (Change Data Capture)

**O que é:** Capturar e replicar apenas as mudanças de dados, não todo dataset

**Por que é importante:**
- Reduz transferência de dados (apenas deltas)
- Permite replicação em tempo real
- Base para data pipelines incremental

**Implementação:**

```
FASE 1: Setup
├─ Criar tabela "vendas_live" com dados iniciais
├─ Habilitar CDC via Iceberg snapshot tracking
└─ Configurar diretório de staging

FASE 2: Captura de Mudanças
├─ INSERT: +10 novos registros
├─ UPDATE: Modificar 5 registros existentes
├─ DELETE: Remover 3 registros (soft delete)
└─ Capturar delta entre snapshots

FASE 3: Validação
├─ Verificar CDC latency < 5 minutos
├─ Comparar delta calculado vs. real
├─ Teste de replicação em tabela espelho
└─ Performance baseline
```

**Script:** `test_cdc_pipeline.py`  
**Validação:** Delta capture correctness, latency < 5 min

---

### 2️⃣ RLAC (Row-Level Access Control)

**O que é:** Controle de acesso no nível de linhas (não apenas tabelas)

**Exemplo:**
```sql
-- User A vê apenas vendas do departamento X
SELECT * FROM vendas 
WHERE department = get_user_department();

-- User B vê apenas vendas do mês atual
SELECT * FROM vendas 
WHERE DATE_TRUNC('month', data_venda) = CURRENT_DATE();
```

**Implementação:**

```
FASE 1: Setup
├─ Criar coluna "department" em tabela vendas
├─ Criar coluna "user_id" para auditoria
├─ Popula dados de teste por departamento
└─ Criar função SQL get_user_dept()

FASE 2: RLAC Logic
├─ Implementar view com filtro automático
├─ Testar acesso de User A (dept=Sales)
├─ Testar acesso de User B (dept=Finance)
├─ Verificar User C sem acesso explícito

FASE 3: Performance Impact
├─ Query SEM filtro RLAC: baseline
├─ Query COM filtro RLAC: compare
├─ Objetivo: < 5% overhead
└─ Partição ajuda performance
```

**Script:** `test_rlac_implementation.py`  
**Validação:** Access control enforced, < 5% performance impact

---

### 3️⃣ BI Integration

**O que é:** Conectar DataLake com ferramentas de BI (Superset, Tableau, Power BI)

**Ferramentas suportadas:**
- Apache Superset (open source, já em container)
- Tableau (if available)
- Power BI (if available)
- Metabase (alternative)

**Implementação:**

```
FASE 1: Superset Setup
├─ Verificar Superset acessível (localhost:8088)
├─ Conectar banco de dados Spark/Iceberg
├─ Criar data source para tabela vendas
└─ Test basic connectivity

FASE 2: Dashboard Creation
├─ Criar dashboard "Sales Overview"
├─ Adicionar chart: Total sales by month
├─ Adicionar chart: Top departments
├─ Adicionar chart: Performance metrics
└─ Test interactivity

FASE 3: Query Performance
├─ Executar queries via Superset
├─ Medir tempo de resposta (target < 30s)
├─ Benchmark vs. direct SQL
└─ Optimize slow queries
```

**Script:** `test_bi_integration.py`  
**Validação:** Dashboard functional, queries < 30s

---

## 📁 Arquivos a Criar

### Scripts Python (em `src/tests/`)

```python
# 1. CDC Pipeline
test_cdc_pipeline.py
├─ Phase 1: Setup tabela "vendas_live"
├─ Phase 2: Aplicar mudanças (INSERT/UPDATE/DELETE)
├─ Phase 3: Capturar deltas entre snapshots
└─ Resultado: CDC_latency < 5 min, correctness 100%

# 2. RLAC Implementation
test_rlac_implementation.py
├─ Phase 1: Setup departamentos e usuários
├─ Phase 2: Implementar views com RLAC
├─ Phase 3: Testar acesso para cada user
└─ Resultado: Acesso controlado, overhead < 5%

# 3. BI Integration
test_bi_integration.py
├─ Phase 1: Conectar ao Superset
├─ Phase 2: Criar data source
├─ Phase 3: Executar queries de teste
└─ Resultado: Dashboard funcional, queries < 30s
```

### Documentação (em `docs/`)

```markdown
results/ITERATION_5_RESULTS.md
├─ Resumo de cada feature
├─ Métricas de sucesso
├─ Lições aprendidas
└─ Recomendações produção

CDC_IMPLEMENTATION.md
├─ Teoria: Como funciona CDC
├─ Implementação: Código Spark
├─ Performance: Otimizações
└─ Troubleshooting: Problemas comuns

RLAC_IMPLEMENTATION.md
├─ Teoria: Row-level security
├─ Implementação: SQL views + Spark
├─ Testing: Casos de uso
└─ Production: Deployment checklist

BI_INTEGRATION_GUIDE.md
├─ Setup Superset
├─ Criar data sources
├─ Build dashboards
└─ Performance tuning
```

---

## 🔍 Critérios de Sucesso

| Feature | Critério | Target |
|---------|----------|--------|
| **CDC** | Latency | < 5 min |
| **CDC** | Correctness | 100% |
| **CDC** | Data loss | 0 |
| **RLAC** | Enforcement | 100% |
| **RLAC** | Overhead | < 5% |
| **RLAC** | Access control | Granular |
| **BI** | Query time | < 30s |
| **BI** | Dashboard latency | < 2s |
| **BI** | Connectivity | 100% uptime |

---

## 📊 Estrutura de Teste

### CDC Pipeline Test
```python
class CDCPipelineTest:
    def setup(self):
        # Criar tabela vendas_live com 50K records
        
    def phase1_initial_snapshot(self):
        # Snapshot 1: baseline
        
    def phase2_apply_changes(self):
        # INSERT 10 novos
        # UPDATE 5 existentes
        # DELETE 3 (soft delete)
        # Snapshot 2: após mudanças
        
    def phase3_capture_delta(self):
        # Comparar snapshots
        # Extrair INSERTs, UPDATEs, DELETEs
        # Validar contagem
        
    def validate(self):
        # Assert: delta correctness
        # Assert: latency < 5 min
        # Assert: no data loss
        
    def performance_metrics(self):
        # CDC overhead %
        # Latency measurements
        # Throughput (records/sec)
```

### RLAC Implementation Test
```python
class RLACImplementationTest:
    def setup(self):
        # Criar departamentos
        # Criar usuários
        # Criar views com filtros
        
    def test_user_a_sees_only_sales_dept(self):
        # User A (Sales) queries
        # Assert: only Sales data
        
    def test_user_b_sees_only_finance_dept(self):
        # User B (Finance) queries
        # Assert: only Finance data
        
    def test_user_c_no_access(self):
        # User C without explicit access
        # Assert: access denied or empty
        
    def performance_impact(self):
        # Query sem RLAC: T1
        # Query com RLAC: T2
        # Assert: (T2-T1)/T1 < 5%
```

### BI Integration Test
```python
class BIIntegrationTest:
    def setup(self):
        # Conectar ao Superset
        # Criar data source
        
    def test_superset_connectivity(self):
        # Assert: connection successful
        # Assert: table accessible
        
    def test_dashboard_creation(self):
        # Create dashboard
        # Add charts
        # Assert: dashboard created
        
    def test_query_performance(self):
        # Execute sample queries
        # Measure latency
        # Assert: queries < 30s
```

---

## 🔗 Fluxo de Implementação

```
START
│
├─ 1. CDC Pipeline
│   ├─ Create test_cdc_pipeline.py
│   ├─ Phase 1: Setup tabela
│   ├─ Phase 2: Apply changes
│   ├─ Phase 3: Capture delta
│   └─ Validate results
│
├─ 2. RLAC Implementation
│   ├─ Create test_rlac_implementation.py
│   ├─ Phase 1: Setup users/depts
│   ├─ Phase 2: Create RLAC views
│   ├─ Phase 3: Test access control
│   └─ Validate performance < 5%
│
├─ 3. BI Integration
│   ├─ Create test_bi_integration.py
│   ├─ Phase 1: Connect Superset
│   ├─ Phase 2: Create dashboard
│   ├─ Phase 3: Test queries
│   └─ Validate < 30s latency
│
├─ 4. Documentation
│   ├─ Create results/ITERATION_5_RESULTS.md
│   ├─ Create CDC_IMPLEMENTATION.md
│   ├─ Create RLAC_IMPLEMENTATION.md
│   ├─ Create BI_INTEGRATION_GUIDE.md
│   └─ Update docs/INDICE_DOCUMENTACAO.md
│
└─ END: 90% project complete ✅
```

---

## ⏱️ Timeline Estimado

| Fase | Duração | Total |
|------|---------|-------|
| **CDC Setup + Test** | 30 min | 30 min |
| **RLAC Setup + Test** | 25 min | 55 min |
| **BI Setup + Test** | 25 min | 80 min |
| **Documentation** | 15 min | 95 min |
| **Final validation** | 5 min | 100 min |

**Total:** ~1.5-2 horas (com possíveis ajustes)

---

## 🎓 Learning Objectives

Ao final desta iteração, você entenderá:

- ✅ Como implementar CDC em Apache Iceberg
- ✅ Como controlar acesso a nível de linha
- ✅ Como integrar DataLake com ferramentas de BI
- ✅ Como medir performance de queries distribuídas
- ✅ Como deployar sistema em produção

---

## 🚦 Status Dashboard

```
┌─────────────────────────────────────────┐
│  ITERATION 5 STATUS - 7 DEC 2025        │
├─────────────────────────────────────────┤
│                                         │
│  CDC Implementation        ⏳ PLANNED   │
│  RLAC Implementation       ⏳ PLANNED   │
│  BI Integration            ⏳ PLANNED   │
│  Documentation             ⏳ PLANNED   │
│                                         │
│  Overall Progress:        0% ▯▯▯▯▯▯▯▯  │
│  ETA Completion:          ~2 hours      │
│  Target Project %:        90%           │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📞 Próximas Ações

1. **Agora:** Confirmar estrutura de Iteração 5
2. **Depois:** Criar `test_cdc_pipeline.py`
3. **Depois:** Criar `test_rlac_implementation.py`
4. **Depois:** Criar `test_bi_integration.py`
5. **Depois:** Executar todos os testes
6. **Depois:** Documentar resultados
7. **Final:** Marcar Iteração 5 como 100% ✅

---

**Documento Criado:** 7 de dezembro de 2025  
**Versão:** 1.0  
**Status:** Ready for Implementation 🚀
