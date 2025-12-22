# 🗺️ Mapa de Migração de Documentação

**Data:** 11 de dezembro de 2025  
**Referência:** Para verificar onde um arquivo foi movido

---

## 📍 Localização Anterior → Nova Localização

### Documentos de Visão Geral

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/INDICE_DOCUMENTACAO.md` | `docs/00-overview/README.md` | ✅ Movido |
| `CONTEXT.md` | `docs/00-overview/CONTEXT.md` | ✅ Movido |
| `EXECUTIVE_SUMMARY.md` | `docs/00-overview/EXECUTIVE_SUMMARY.md` | ✅ Movido |

### Arquitetura e Design

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/Projeto.md` | `docs/10-architecture/Projeto.md` | ✅ Movido |

### Operações - Runbooks

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `etc/runbooks/RUNBOOK_STARTUP.md` | `docs/20-operations/runbooks/RUNBOOK_STARTUP.md` | ✅ Movido |
| `etc/runbooks/RUNBOOK_SHUTDOWN.md` | `docs/20-operations/runbooks/RUNBOOK_SHUTDOWN.md` | ✅ Movido |
| `etc/runbooks/RUNBOOK_TROUBLESHOOTING.md` | `docs/20-operations/runbooks/RUNBOOK_TROUBLESHOOTING.md` | ✅ Movido |
| `etc/runbooks/RUNBOOK_BACKUP_RESTORE.md` | `docs/20-operations/runbooks/RUNBOOK_BACKUP_RESTORE.md` | ✅ Movido |
| `etc/runbooks/RUNBOOK_SCALING.md` | `docs/20-operations/runbooks/RUNBOOK_SCALING.md` | ✅ Movido |

### Operações - Checklists

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/PHASE_1_CHECKLIST.md` | `docs/20-operations/checklists/PHASE_1_CHECKLIST.md` | ✅ Duplicata removida* |
| `PRODUCTION_DEPLOYMENT_CHECKLIST.md` | `docs/20-operations/checklists/PRODUCTION_DEPLOYMENT_CHECKLIST.md` | ✅ Duplicata removida* |
| `PROXIMOS_PASSOS_CHECKLIST.md` | `docs/20-operations/checklists/PROXIMOS_PASSOS_CHECKLIST.md` | ✅ Duplicata removida* |
| `ROTATE_CREDENTIALS.md` (novo) | `docs/20-operations/checklists/ROTATE_CREDENTIALS.md` | ✅ Criado |

*Duplicatas removidas da raiz; versão original em docs/20-operations/checklists/ foi mantida

### Iterações - Planos

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/ITERATION_5_PLAN.md` | `docs/30-iterations/plans/ITERATION_5_PLAN.md` | ✅ Duplicata removida |
| `ITERATION_6_PLAN.md` | `docs/30-iterations/plans/ITERATION_6_PLAN.md` | ✅ Duplicata removida |
| `ITERATION_7_PLAN.md` | `docs/30-iterations/plans/ITERATION_7_PLAN.md` | ✅ Duplicata removida |

### Iterações - Resultados

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/ITERATION_1_RESULTS.md` | `docs/30-iterations/results/ITERATION_1_RESULTS.md` | ✅ Duplicata removida |
| `docs/ITERATION_2_RESULTS.md` | `docs/30-iterations/results/ITERATION_2_RESULTS.md` | ✅ Duplicata removida |
| `docs/ITERATION_3_RESULTS.md` | `docs/30-iterations/results/ITERATION_3_RESULTS.md` | ✅ Duplicata removida |
| `docs/ITERATION_5_RESULTS.md` | `docs/30-iterations/results/ITERATION_5_RESULTS.md` | ✅ Duplicata removida |
| `ITERATION_6_PHASE1_REPORT.md` | `docs/30-iterations/results/ITERATION_6_PHASE1_REPORT.md` | ✅ Movido |
| `ITERATION_6_PHASE3_REPORT.md` | `docs/30-iterations/results/ITERATION_6_PHASE3_REPORT.md` | ✅ Movido |
| `docs/ITERATION_7_PROGRESS.md` | `docs/30-iterations/results/ITERATION_7_PROGRESS.md` | ✅ Movido |
| `docs/30-iterations/STATUS.md` (novo) | `docs/30-iterations/STATUS.md` | ✅ Criado |

### Troubleshooting

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/PROBLEMAS_ESOLUCOES.md` | `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` | ✅ Duplicata removida |

*Versão original já estava em docs/40-troubleshooting/

### Referências Técnicas

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/VARIÁVEIS_ENV.md` | `docs/50-reference/env.md` | ℹ️ Consolidado |
| `SETUP_VARIAVEIS_ENV.md` | `docs/50-reference/env.md` | ℹ️ Consolidado |
| `docs/50-reference/env.md` (novo) | `docs/50-reference/env.md` | ✅ Criado |
| `docs/50-reference/endpoints.md` (novo) | `docs/50-reference/endpoints.md` | ✅ Criado |
| `docs/50-reference/portas_acls.md` (novo) | `docs/50-reference/portas_acls.md` | ✅ Criado |
| `docs/50-reference/credenciais_rotina.md` (novo) | `docs/50-reference/credenciais_rotina.md` | ✅ Criado |

### Decisões Arquiteturais

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docs/60-decisions/ADR-template.md` (novo) | `docs/60-decisions/ADR-template.md` | ✅ Criado |
| (pendentes) | `docs/60-decisions/ADR-*.md` | 🔄 Existentes |

### Arquivo Histórico

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `AIRFLOW_HARDENING_CONCLUSION.md` | `docs/99-archive/AIRFLOW_HARDENING_CONCLUSION.md` | ✅ Movido |
| `AIRFLOW_IMPLEMENTATION_PLAN.md` | `docs/99-archive/AIRFLOW_IMPLEMENTATION_PLAN.md` | ✅ Movido |
| `AIRFLOW_IP_UPDATE.md` | `docs/99-archive/AIRFLOW_IP_UPDATE.md` | ✅ Movido |
| `AIRFLOW_PLAN_SUMMARY.md` | `docs/99-archive/AIRFLOW_PLAN_SUMMARY.md` | ✅ Movido |
| `AIRFLOW_QUICK_START.md` | `docs/99-archive/AIRFLOW_QUICK_START.md` | ✅ Movido |
| `AIRFLOW_SECURITY_HARDENING.md` | `docs/99-archive/AIRFLOW_SECURITY_HARDENING.md` | ✅ Movido |
| `AIRFLOW_SECURITY_INDEX.md` | `docs/99-archive/AIRFLOW_SECURITY_INDEX.md` | ✅ Movido |
| `AIRFLOW_SECURITY_SUMMARY.md` | `docs/99-archive/AIRFLOW_SECURITY_SUMMARY.md` | ✅ Movido |
| `INDICE_FINAL_COMPLETO.md` | `docs/99-archive/INDICE_FINAL_COMPLETO.md` | ✅ Movido |
| `ITERATION_6_OVERVIEW.txt` | `docs/99-archive/ITERATION_6_OVERVIEW.txt` | ✅ Movido |
| `START_PHASE_1_NOW.md` | `docs/99-archive/START_PHASE_1_NOW.md` | ✅ Movido |
| `TODO.md` | `docs/99-archive/TODO.md` | ✅ Movido |

### Infraestrutura - Provisionamento

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `deploy.sh` | `infra/provisioning/deploy.sh` | ✅ Movido |
| `complete_spark_config.sh` | `infra/provisioning/complete_spark_config.sh` | ✅ Movido |
| `deploy_iceberg_catalog.sh` | `infra/provisioning/deploy_iceberg_catalog.sh` | ✅ Movido |
| `deploy_via_jump.sh` | `infra/provisioning/deploy_via_jump.sh` | ✅ Movido |
| `deploy_iceberg.sh` | `infra/provisioning/deploy_iceberg.sh` | ✅ Movido |
| `install_spark.sh` | `infra/provisioning/install_spark.sh` | ✅ Movido |
| `setup_ssh_hive_trino.sh` | _removido_ | ❌ Obsoleto (substituído por scripts/enforce_canonical_ssh_key.sh + docs/10-architecture/Guia_Chave_Canonica_SSH.md) |
| `update_trino_config.sh` | `infra/provisioning/update_trino_config.sh` | ✅ Movido |
| `deploy_iceberg_via_hive.py` | `infra/provisioning/deploy_iceberg_via_hive.py` | ✅ Movido |

### Infraestrutura - Diagnósticos

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `fix_tests_local_mode.py` | `infra/diagnostics/fix_tests_local_mode.py` | ✅ Movido |
| `test_thrift_protocol.py` | `infra/diagnostics/test_thrift_protocol.py` | ✅ Movido |
| `test_spark_integration.py` | `infra/diagnostics/test_spark_integration.py` | ✅ Movido |
| `test_iceberg_simple.py` | `infra/diagnostics/test_iceberg_simple.py` | ✅ Movido |
| `test_hive_connectivity.py` | `infra/diagnostics/test_hive_connectivity.py` | ✅ Movido |
| `setup_ssh_trino.py` | _removido_ | ❌ Obsoleto (acesso SSH padronizado pela chave canônica) |

### Infraestrutura - Serviços

| Anterior | Nova Localização | Status |
|----------|-----------------|--------|
| `docker-compose.gitea.yml` | `infra/services/docker-compose.gitea.yml` | ✅ Movido |
| `hive-metastore.service` | `infra/services/hive-metastore.service` | ✅ Movido |

### Novos Documentos Criados

| Nome | Localização | Tipo |
|------|-------------|------|
| **CONTRIBUTING.md** | `docs/CONTRIBUTING.md` | Guia de Contribuição |
| **QUICK_NAV.md** | `docs/QUICK_NAV.md` | Guia de Navegação |
| **check-doc-links.sh** | `docs/check-doc-links.sh` | Script de Validação |
| **lint-markdown.yml** | `.github/workflows/lint-markdown.yml` | CI/CD Workflow |
| **REORGANIZACAO_SUMMARY.md** | `docs/REORGANIZACAO_SUMMARY.md` | Resumo da Reorganização |
| **CONCLUSAO_REORGANIZACAO.md** | `docs/CONCLUSAO_REORGANIZACAO.md` | Conclusão |

### Scripts Removidos / Obsoletos

| Script | Status | Observação |
|--------|--------|------------|
| `scripts/ssh_and_run_tests.sh` | ❌ Removido | Substituído por testes locais/CI; usar `scripts/test_canonical_ssh.sh` para validação de acesso. |
| `infra/provisioning/setup_ssh_ct.ps1` | ❌ Removido | Fluxo de chave canônica consolidado em `scripts/enforce_canonical_ssh_key.sh` + guia em `docs/10-architecture/Guia_Chave_Canonica_SSH.md`. |
| **MAPA_MIGRACAO.md** | `docs/MAPA_MIGRACAO.md` | Este arquivo |
| **env.md** | `docs/50-reference/env.md` | Referência Técnica |
| **endpoints.md** | `docs/50-reference/endpoints.md` | Referência Técnica |
| **portas_acls.md** | `docs/50-reference/portas_acls.md` | Referência Técnica |
| **credenciais_rotina.md** | `docs/50-reference/credenciais_rotina.md` | Referência Técnica |

---

## 🔍 Procurando um Arquivo?

### Se você tem o nome do arquivo:
1. Procure nesta tabela (acima)
2. Note a nova localização
3. Acesse o novo caminho

### Se você não tem certeza do nome:
1. Consulte [docs/QUICK_NAV.md](docs/QUICK_NAV.md)
2. Ou navegue por categoria em [docs/00-overview/README.md](docs/00-overview/README.md)

### Se arquivo não está listado:
1. Pode estar em `docs/99-archive/` (histórico)
2. Ou em `docs/ARQUIVO/` (backup antigo)
3. Consulte [docs/INDICE_DOCUMENTACAO.md](docs/INDICE_DOCUMENTACAO.md) (índice legado)

---

## 🚀 Como Usar Este Mapa

**Cenário 1: Migração de Links em Scripts**
```bash
# Procurar referência antiga
grep -r "AIRFLOW_HARDENING_CONCLUSION" *.sh *.py

# Atualizar para novo caminho
sed -i 's|AIRFLOW_HARDENING_CONCLUSION|docs/99-archive/AIRFLOW_HARDENING_CONCLUSION|g' script.sh
```

**Cenário 2: Atualizar Referências em Docs**
```bash
# Procurar referência quebrada
grep -r "etc/runbooks/RUNBOOK" docs/

# Atualizar para novo caminho
sed -i 's|etc/runbooks/RUNBOOK|docs/20-operations/runbooks/RUNBOOK|g' docs/*.md
```

**Cenário 3: Auditar Integridade**
```bash
# Verificar se arquivo novo existe
test -f "docs/50-reference/env.md" && echo "✓ Arquivo existe" || echo "✗ Arquivo não encontrado"

# Validar todos os links
bash docs/check-doc-links.sh docs/
```

---

## 📊 Estatísticas de Migração

| Categoria | Arquivos | Status |
|-----------|----------|--------|
| Documentação | ~25 | ✅ Migrados |
| Duplicatas Removidas | ~12 | ✅ Removidas |
| Novos Documentos | 11 | ✅ Criados |
| Scripts/Automação | 2 | ✅ Adicionados |
| **TOTAL** | **~50** | **100% ✅** |

---

## ⚠️ Importante

### Caminhos Antigos
Os caminhos antigos NÃO funcionam mais. Use os novos caminhos listados neste mapa.

### Compatibilidade
Se você tem scripts referenciando caminhos antigos, atualize-os usando o mapa acima.

### Redirecionamento
Não há redirecionamento automático. Use este mapa para encontrar novo caminho.

---

## 🔗 Referências Cruzadas

- [Conclusão da Reorganização](CONCLUSAO_REORGANIZACAO.md)
- [Resumo da Reorganização](REORGANIZACAO_SUMMARY.md)
- [Guia Rápido de Navegação](QUICK_NAV.md)
- [Guia de Contribuição](CONTRIBUTING.md)
- [Novo Índice](00-overview/README.md)

---

**Última Atualização:** 11 de dezembro de 2025  
**Versão:** 1.0
