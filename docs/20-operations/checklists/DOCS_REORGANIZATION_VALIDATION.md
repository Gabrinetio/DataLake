# Checklist de Validação - Reorganização de Documentação

**Data:** 11 de dezembro de 2025  
**Executor:** [Seu nome]  
**Status:** Pendente ⏳

---

## ✅ Fase 1: Estrutura de Diretórios

- [x] `docs/00-overview/` criado com README.md, CONTEXT.md, EXECUTIVE_SUMMARY.md
- [x] `docs/10-architecture/` criado com Projeto.md
- [x] `docs/20-operations/{runbooks,checklists}/` criado
- [x] `docs/30-iterations/{plans,results}/` criado com STATUS.md
- [x] `docs/40-troubleshooting/` criado com PROBLEMAS_ESOLUCOES.md
- [x] `docs/50-reference/` criado com env.md, endpoints.md, portas_acls.md, credenciais_rotina.md
- [x] `docs/60-decisions/` criado com ADR-template.md
- [x] `docs/99-archive/` criado com arquivos antigos
- [x] `infra/{provisioning,diagnostics,services}/` criado
- [x] `artifacts/{results,logs,reports}/` criado

**Status:** ✅ 100% Concluído

---

## ✅ Fase 2: Documentos-Chave Movidos/Reorganizados

### Visão Geral
- [x] INDICE_DOCUMENTACAO.md → docs/00-overview/README.md
- [x] CONTEXT.md → docs/00-overview/CONTEXT.md
- [x] EXECUTIVE_SUMMARY.md → docs/00-overview/EXECUTIVE_SUMMARY.md
- [x] Projeto.md → docs/10-architecture/Projeto.md

### Operações
- [x] etc/runbooks/*.md → docs/20-operations/runbooks/
- [x] PHASE_1_CHECKLIST.md → docs/20-operations/checklists/ (duplicata removida)
- [x] PRODUCTION_DEPLOYMENT_CHECKLIST.md → docs/20-operations/checklists/ (duplicata removida)
- [x] PROXIMOS_PASSOS_CHECKLIST.md → docs/20-operations/checklists/ (duplicata removida)

### Iterações
- [x] ITERATION_*_PLAN.md → docs/30-iterations/plans/
- [x] ITERATION_*_RESULTS.md → docs/30-iterations/results/
- [x] ITERATION_6_PHASE*_REPORT.md → docs/30-iterations/results/
- [x] ITERATION_7_PROGRESS.md → docs/30-iterations/results/
- [x] docs/30-iterations/STATUS.md criado com tabelação

### Troubleshooting
- [x] PROBLEMAS_ESOLUCOES.md → docs/40-troubleshooting/ (duplicata removida)

### Infraestrutura
- [x] docker-compose.gitea.yml → infra/services/
- [x] hive-metastore.service → infra/services/
- [x] deploy*.sh → infra/provisioning/
- [x] install_spark.sh → infra/provisioning/
- [x] deploy_iceberg_via_hive.py → infra/provisioning/
- [x] update_trino_config.sh → infra/provisioning/
- [x] test_*.py, fix_*.py → infra/diagnostics/

### Arquivo
- [x] AIRFLOW_*.md → docs/99-archive/ (8 arquivos)
- [x] INDICE_FINAL_COMPLETO.md → docs/99-archive/
- [x] TODO.md → docs/99-archive/
- [x] START_PHASE_1_NOW.md → docs/99-archive/
- [x] ITERATION_6_OVERVIEW.txt → docs/99-archive/

**Status:** ✅ 100% Concluído

---

## ✅ Fase 3: Novos Documentos e Referências

### Referências Técnicas (docs/50-reference/)
- [x] env.md - Variáveis consolidadas
- [x] endpoints.md - URLs e acesso
- [x] portas_acls.md - Firewall e ACLs
- [x] credenciais_rotina.md - Rotação de credenciais

### Decisões Arquiteturais (docs/60-decisions/)
- [x] ADR-template.md criado
- [x] ADRs pendentes já existentes catalogados

### Documentação Geral (docs/)
- [x] CONTRIBUTING.md criado com guia de contribuição
- [x] check-doc-links.sh criado para validação
- [x] REORGANIZACAO_SUMMARY.md criado

### CI/CD (.github/workflows/)
- [x] lint-markdown.yml criado para validação automática

**Status:** ✅ 100% Concluído

---

## ✅ Fase 4: Atualizações e Links

### Documentação Principal
- [x] README.md (raiz) atualizado com nova estrutura
- [x] docs/00-overview/README.md atualizado como índice novo
- [x] Todos os links internos revisados

### Convenções Implementadas
- [x] Nomenclatura: RUNBOOK_NOUN_VERB.md
- [x] Nomenclatura: ITERATION_N_PLAN.md, ITERATION_N_RESULTS.md
- [x] Nomenclatura: ADR-YYYYMMDD-slug.md
- [x] Nomenclatura: lowercase_with_underscore.{sh,py}
- [x] Shebang presente em scripts executáveis
- [x] chmod +x em scripts Shell

**Status:** ✅ 100% Concluído

---

## 📋 Fase 5: Testes e Validação (A FAZER)

### Validação de Links
- [ ] Executar `bash docs/check-doc-links.sh docs/`
- [ ] Verificar se todos os links estão válidos
- [ ] Corrigir links quebrados encontrados
- [ ] Testar links em CI/CD

### Validação de Documentação
- [ ] Revisar docs/00-overview/README.md (novo índice)
- [ ] Revisar docs/CONTRIBUTING.md (guia de contribuição)
- [ ] Revisar docs/50-reference/ (referências completas)
- [ ] Revisar docs/60-decisions/ (ADRs)

### Validação de Scripts
- [ ] Testar docs/check-doc-links.sh localmente
- [ ] Verificar se .github/workflows/lint-markdown.yml funciona
- [ ] Procurar referências a caminhos antigos em scripts
  ```bash
  grep -r "INDICE_DOCUMENTACAO\|PROBLEMAS_ESOLUCOES" . --include="*.ps1" --include="*.sh" --include="*.py" 2>/dev/null | grep -v "docs/00-overview\|docs/40-troubleshooting\|99-archive"
  ```

### Comunicação
- [ ] Atualizar README.md com referências à nova estrutura
- [ ] Comunicar ao team sobre nova organização
- [ ] Treinar time sobre onde colocar novos documentos
- [ ] Atualizar .github/copilot-instructions.md se necessário

**Status:** ⏳ Pendente

---

## 🔧 Fase 6: Ações Recomendadas Pós-Validação

### Curto Prazo (Semana 1)
- [ ] Atualizar `create_issues_from_problems.ps1` para novo caminho de PROBLEMAS_ESOLUCOES.md
- [ ] Procurar por `grep -r "docs/" *.ps1 *.sh` e verificar referências quebradas
- [ ] Testar CI/CD de documentação em pull request de teste
- [ ] Revisar e padronizar templates de runbooks/checklists

### Médio Prazo (Semana 2-3)
- [ ] Completar ADRs pendentes em docs/60-decisions/
- [ ] Consolidar duplicatas de conteúdo
- [ ] Adicionar missing links/referências
- [ ] Implementar spell-check português em CI/CD

### Longo Prazo (Mês 2)
- [ ] Deprecar docs/INDICE_DOCUMENTACAO.md (índice legado)
- [ ] Migrar completamente para docs/00-overview/README.md
- [ ] Implementar versionamento de documentação
- [ ] Arquivar docs restantes em docs/99-archive/

**Status:** 📋 Planejado

---

## 📊 Resumo Executivo

| Item | Concluído | Total | % |
|------|-----------|-------|---|
| Pastas criadas | 16 | 16 | 100% |
| Docs movidos/reorganizados | 25 | 25 | 100% |
| Duplicatas removidas | 12 | 12 | 100% |
| Novos documentos | 10 | 10 | 100% |
| Testes/Validação | 0 | 8 | 0% |
| **TOTAL FASE 1-4** | **63** | **63** | **100%** |

---

## ✍️ Assinatura e Aprovação

### Executor
- **Nome:** _________________________
- **Data:** _________________________
- **Resultado:** ☐ Sucesso | ☐ Com Alertas | ☐ Falhou

### Validação
- **Revisor:** _________________________
- **Data:** _________________________
- **Observações:** 
  ```
  [Espaço para observações]
  ```

### Aprovação Final
- **Aprovador:** _________________________
- **Data:** _________________________
- **Status Final:** ☐ Aprovado | ☐ Aprovado com restrições | ☐ Rejeitado

---

## 📝 Notas

```
[Espaço para notas adicionais, problemas encontrados, etc.]




```

---

## Referências

- [docs/00-overview/README.md](../../00-overview/README.md) - Novo índice
- [docs/CONTRIBUTING.md](../../CONTRIBUTING.md) - Guia de contribuição
- [docs/REORGANIZACAO_SUMMARY.md](../../REORGANIZACAO_SUMMARY.md) - Resumo da reorganização
- [README.md](../../../README.md) - Documentação principal do projeto

---

**Última Atualização:** 11 de dezembro de 2025
