# 📍 Guia de Navegação Rápida

**Última atualização:** 11 de dezembro de 2025

---

## 🏠 Você está aqui

```
DataLake_FB-v2/
├── README.md ← Comece aqui para visão geral
├── docs/ ← Toda a documentação
│   └── ... (ver abaixo)
└── ... (código, infra, testes)
```

---

## 📚 Encontre o que você procura

### "Preciso entender o projeto como um todo"
1. Comece por: [README.md](../README.md) (raiz)
2. Depois leia: [docs/00-overview/README.md](00-overview/README.md) (novo índice)
3. Referência: [docs/00-overview/CONTEXT.md](00-overview/CONTEXT.md) (contexto técnico)

### "Preciso entender a arquitetura"
→ [docs/10-architecture/Projeto.md](10-architecture/Projeto.md)

### "Qual é o status de cada iteração?"
→ [docs/30-iterations/STATUS.md](30-iterations/STATUS.md) (tabelação centralizada)

### "Preciso de um runbook para operação X"
→ [docs/20-operations/runbooks/](20-operations/runbooks/)
- RUNBOOK_STARTUP.md
- RUNBOOK_SHUTDOWN.md
- RUNBOOK_BACKUP_RESTORE.md
- RUNBOOK_TROUBLESHOOTING.md

### "Preciso fazer um checklist"
→ [docs/20-operations/checklists/](20-operations/checklists/)
- PHASE_1_CHECKLIST.md
- PRODUCTION_DEPLOYMENT_CHECKLIST.md
- ROTATE_CREDENTIALS.md

### "Encontrei um erro/problema"
1. Procure em: [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](40-troubleshooting/PROBLEMAS_ESOLUCOES.md)
2. Se não encontrar, adicione como nova entrada

### "Preciso de variáveis de ambiente"
→ [docs/50-reference/env.md](50-reference/env.md)

### "Preciso saber quais são os endpoints"
→ [docs/50-reference/endpoints.md](50-reference/endpoints.md)

### "Preciso configurar firewall/ACLs"
→ [docs/50-reference/portas_acls.md](50-reference/portas_acls.md)

### "Preciso rotacionar credenciais"
→ [docs/50-reference/credenciais_rotina.md](50-reference/credenciais_rotina.md)

### "Preciso entender uma decisão arquitetural"
→ [docs/60-decisions/](60-decisions/) (ADRs)

### "Vou contribuir com documentação"
→ [docs/CONTRIBUTING.md](CONTRIBUTING.md) (guia de contribuição)

---

## 🗂️ Estrutura Completa

```
docs/
│
├── 📌 00-overview/
│   ├── README.md ........................ Novo índice (em transição)
│   ├── CONTEXT.md ....................... Contexto do projeto
│   └── EXECUTIVE_SUMMARY.md ............ Sumário executivo
│
├── 🏗️ 10-architecture/
│   └── Projeto.md ....................... Arquitetura técnica completa
│
├── ⚙️ 20-operations/
│   ├── runbooks/
│   │   ├── RUNBOOK_STARTUP.md
│   │   ├── RUNBOOK_SHUTDOWN.md
│   │   ├── RUNBOOK_TROUBLESHOOTING.md
│   │   └── RUNBOOK_BACKUP_RESTORE.md
│   └── checklists/
│       ├── PHASE_1_CHECKLIST.md
│       ├── PRODUCTION_DEPLOYMENT_CHECKLIST.md
│       ├── PROXIMOS_PASSOS_CHECKLIST.md
│       ├── ROTATE_CREDENTIALS.md
│       └── DOCS_REORGANIZATION_VALIDATION.md
│
├── 📊 30-iterations/
│   ├── STATUS.md ........................ Tabelação de iterações
│   ├── plans/
│   │   ├── ITERATION_5_PLAN.md
│   │   ├── ITERATION_6_PLAN.md
│   │   └── ITERATION_7_PLAN.md
│   └── results/
│       ├── ITERATION_1_RESULTS.md
│       ├── ITERATION_5_RESULTS.md
│       ├── ITERATION_6_PHASE1_REPORT.md
│       ├── ITERATION_6_PHASE3_REPORT.md
│       └── ITERATION_7_PROGRESS.md
│
├── 🐛 40-troubleshooting/
│   └── PROBLEMAS_ESOLUCOES.md ........ Fonte única de problemas
│
├── 📖 50-reference/
│   ├── env.md .......................... Variáveis de ambiente
│   ├── endpoints.md .................... URLs e acesso
│   ├── portas_acls.md ................. Firewall e ACLs
│   └── credenciais_rotina.md ......... Rotação de credenciais
│
├── 🔏 60-decisions/
│   ├── ADR-template.md ............... Template para novos ADRs
│   ├── ADR-20241210-iceberg-catalog.md
│   ├── ADR-20241210-minio-s3-fix.md
│   └── ADR-20241210-rlac-fix.md
│
├── 📦 99-archive/
│   ├── AIRFLOW_*.md ................... Documentos antigos
│   ├── TODO.md, START_PHASE_1_NOW.md, etc.
│
├── 🔗 INDICE_DOCUMENTACAO.md ......... Índice legado (será deprecated)
├── 📝 CONTRIBUTING.md ................ Guia de contribuição
├── ✅ check-doc-links.sh ............ Validador de links
└── 📋 REORGANIZACAO_SUMMARY.md ..... Resumo da reorganização
```

---

## 🔍 Dicas de Navegação

### Via VS Code
```
Ctrl+P (Cmd+P no Mac)
Digitar: "docs/" para listar todos os arquivos
```

### Via Terminal
```bash
# Ver todos os markdowns em uma seção
ls docs/20-operations/runbooks/

# Procurar por palavra-chave
grep -r "palavra-chave" docs/

# Validar links
bash docs/check-doc-links.sh docs/
```

### Via GitHub
```
Navegar para: /docs e explorar estrutura
```

---

## 🆘 Procedimento para Encontrar Informação

### 1️⃣ Sabe exatamente o que procura?
→ Use `Ctrl+P` em VS Code ou `grep -r` no terminal

### 2️⃣ Sabe o tipo de documento?
→ Veja a seção apropriada neste guia

### 3️⃣ Não tem certeza?
→ Comece por [docs/00-overview/README.md](00-overview/README.md)

### 4️⃣ Não encontrou?
→ Procure em [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](40-troubleshooting/PROBLEMAS_ESOLUCOES.md)

### 5️⃣ Ainda não encontrou?
→ Consulte o [Índice legado](INDICE_DOCUMENTACAO.md) (será deprecated em breve)

---

## 🎯 Cenários Rápidos

### "Estou iniciando um novo feature"
1. Consulte [CONTEXT.md](00-overview/CONTEXT.md) para entender stack
2. Leia [Projeto.md](10-architecture/Projeto.md) para arquitetura
3. Crie ADR em [docs/60-decisions/](60-decisions/) se necessário
4. Documente em [CONTRIBUTING.md](CONTRIBUTING.md)

### "Preciso fazer deployment em produção"
1. Leia [PRODUCTION_DEPLOYMENT_CHECKLIST.md](20-operations/checklists/PRODUCTION_DEPLOYMENT_CHECKLIST.md)
2. Consulte [endpoints.md](50-reference/endpoints.md) para IPs/portas
3. Use [portas_acls.md](50-reference/portas_acls.md) para firewall
4. Siga runbook apropriado em [docs/20-operations/runbooks/](20-operations/runbooks/)

### "Estou resolvendo um problema"
1. Procure em [PROBLEMAS_ESOLUCOES.md](40-troubleshooting/PROBLEMAS_ESOLUCOES.md)
2. Se solução encontrada, siga os passos
3. Se não encontrou, procure em [Projeto.md](10-architecture/Projeto.md) (Seção 16)
4. Se ainda não resolver, documente como novo problema

### "Vou contribuir com documentação"
1. Leia [CONTRIBUTING.md](CONTRIBUTING.md) para convenções
2. Coloque documento no diretório correto
3. Atualize links e índices
4. Execute `bash check-doc-links.sh docs/` para validar
5. Faça PR

---

## 🚀 Atalhos Úteis

| O que você quer | Comando/Path |
|-----------------|--------------|
| Novo runbook | `cp docs/20-operations/runbooks/RUNBOOK_TEMPLATE.md docs/20-operations/runbooks/RUNBOOK_NOVO.md` |
| Novo ADR | `cp docs/60-decisions/ADR-template.md docs/60-decisions/ADR-YYYYMMDD-slug.md` |
| Validar docs | `bash docs/check-doc-links.sh docs/` |
| Ver planos | `ls docs/30-iterations/plans/` |
| Ver resultados | `ls docs/30-iterations/results/` |
| Troubleshooting | `open docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md` |

---

## 📞 Precisa de Ajuda?

| Questão | Resposta |
|---------|----------|
| "Onde fica X?" | Veja [Estrutura Completa](#estrutura-completa) acima |
| "Como escrever docs?" | Consulte [docs/CONTRIBUTING.md](CONTRIBUTING.md) |
| "Links estão quebrados?" | Execute `bash docs/check-doc-links.sh docs/` |
| "Dúvida sobre feature?" | Leia [docs/00-overview/CONTEXT.md](00-overview/CONTEXT.md) |
| "Erro durante operação?" | Procure em [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](40-troubleshooting/PROBLEMAS_ESOLUCOES.md) |

---

## ✨ Próximos Passos

- [ ] Ler [docs/00-overview/README.md](00-overview/README.md) (novo índice)
- [ ] Entender [docs/00-overview/CONTEXT.md](00-overview/CONTEXT.md) (contexto)
- [ ] Navegar [docs/10-architecture/Projeto.md](10-architecture/Projeto.md) (arquitetura)
- [ ] Consultar [docs/30-iterations/STATUS.md](30-iterations/STATUS.md) (progresso)
- [ ] Marcar [docs/CONTRIBUTING.md](CONTRIBUTING.md) como favorito

---

**🎯 Objetivo:** Documentação clara, organizada e fácil de navegar

**📅 Atualizado:** 11 de dezembro de 2025

**👉 [Voltar ao README](../README.md)**
