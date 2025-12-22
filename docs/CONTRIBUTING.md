# Guia de Contribuição de Documentação

Convenções e boas práticas para adicionar e manter documentação no DataLake FB.

## 1. Estrutura de Diretórios

### Onde colocar cada tipo de arquivo?

| Tipo de Documento | Caminho | Exemplo |
|------------------|---------|---------|
| **Visão Geral** | `docs/00-overview/` | README.md, CONTEXT.md, EXECUTIVE_SUMMARY.md |
| **Arquitetura** | `docs/10-architecture/` | Projeto.md, diagrams, data models |
| **Runbooks** | `docs/20-operations/runbooks/` | RUNBOOK_STARTUP.md, RUNBOOK_BACKUP.md |
| **Checklists** | `docs/20-operations/checklists/` | PHASE_1_CHECKLIST.md, PRODUCTION_DEPLOYMENT_CHECKLIST.md |
| **Planos de Iteração** | `docs/30-iterations/plans/` | ITERATION_7_PLAN.md |
| **Resultados de Iteração** | `docs/30-iterations/results/` | ITERATION_7_PROGRESS.md |
| **Troubleshooting** | `docs/40-troubleshooting/` | PROBLEMAS_ESOLUCOES.md, erros conhecidos |
| **Referência** | `docs/50-reference/` | env.md, endpoints.md, portas_acls.md |
| **Decisões Arquiteturais** | `docs/60-decisions/` | ADR-*.md (Architecture Decision Records) |
| **Histórico/Arquivo** | `docs/99-archive/` | Documentos obsoletos, AIRFLOW_*.md |
| **Infra & Scripts** | `infra/provisioning/` | Scripts de instalação e setup |
| **Diagnósticos** | `infra/diagnostics/` | Scripts de teste e troubleshooting |
| **Configurações** | `infra/services/` | docker-compose.yml, *.service |
| **Artefatos** | `artifacts/results/` | Resultados de testes, JSON outputs |

## 2. Convenções de Nomenclatura

### Arquivos Markdown

```
# Formato padrão: lowercase com underscore

docs/
├── 00-overview/
│   ├── README.md                   # Índice principal
│   ├── CONTEXT.md                  # Contexto do projeto
│   ├── EXECUTIVE_SUMMARY.md        # Resumo executivo
│
├── 20-operations/
│   ├── runbooks/
│   │   ├── RUNBOOK_STARTUP.md      # Para: startup (majúsculas)
│   │   ├── RUNBOOK_SHUTDOWN.md
│   │   ├── RUNBOOK_BACKUP_RESTORE.md  # Formato: RUNBOOK_NOUN_VERB.md
│   │
│   ├── checklists/
│   │   ├── PHASE_1_CHECKLIST.md    # Para: fase específica
│   │   ├── PRODUCTION_DEPLOYMENT_CHECKLIST.md
│
├── 30-iterations/
│   ├── plans/
│   │   ├── ITERATION_5_PLAN.md     # ITERATION_N_PLAN.md
│   │   ├── ITERATION_6_PLAN.md
│   │
│   ├── results/
│   │   ├── ITERATION_5_RESULTS.md  # ITERATION_N_RESULTS.md
│   │   ├── ITERATION_6_PHASE1_REPORT.md  # Para múltiplas fases
│
├── 60-decisions/
│   ├── ADR-20241210-iceberg-catalog.md  # ADR-YYYYMMDD-slug.md
│   ├── ADR-template.md               # Template para novo ADR
```

**Regras:**
- Nomes em MAIÚSCULAS: RUNBOOK_*, ITERATION_*, CHECKLIST_*
- Nomes em lowercase: env.md, endpoints.md, credentials.md
- ADRs: `ADR-YYYYMMDD-slug.md`
- Separador: underscore (`_`), hífen em ADRs
- Sem espaços, sem acentos especiais no filename

### Scripts (Shell, Python, PowerShell)

```
infra/provisioning/
├── deploy.sh                       # Scripts executáveis: lowercase.sh
├── deploy_iceberg_via_hive.py

infra/diagnostics/
├── test_iceberg_simple.py
├── check_connectivity.sh

.github/workflows/
├── lint-markdown.yml               # CI/CD: lowercase.yml
├── test-docs.yml
```

**Regras:**
- Lowercase com underscore
- Extensão: .sh (bash), .py (Python), .ps1 (PowerShell)
- Executáveis: `chmod +x script.sh`
- Usar shebang: `#!/bin/bash` ou `#!/usr/bin/env python3`

## 3. Estrutura de Documentos Markdown

### Cabeçalho Padrão

```markdown
# Título do Documento

**Última Atualização:** YYYY-MM-DD | **Autor:** [nome] | **Status:** [Draft|Review|Published]

Breve descrição (1-2 parágrafos) do propósito do documento.

---

## Tabela de Conteúdos

- [Seção 1](#seção-1)
- [Seção 2](#seção-2)
- [Referências](#referências)

---

## Seção 1

Conteúdo...

## Referências

- [docs/10-architecture/Projeto.md](10-architecture/Projeto.md)
- [docs/20-operations/runbooks/](20-operations/runbooks/)
```

### Runbooks - Estrutura Obrigatória

```markdown
# RUNBOOK: [Nome da Operação]

**Objetivo:** Breve descrição

**Pré-requisitos:**
- Acesso SSH a [servers]
- Variáveis de ambiente carregadas
- [Outro pré-requisito]

**Estimativa de Tempo:** XX minutos

---

## Passos

### 1. [Descrição do Passo]

```bash
# Comando 1
$ comando_aqui

# Comando 2
$ outro_comando
```

**Resultado esperado:** [O que deve acontecer]

### 2. [Próximo Passo]

...

---

## Troubleshooting

| Erro | Causa | Solução |
|------|-------|---------|
| `error: xxx` | Xxx não está configurado | Executar `comando` |

---

## Rollback

Se algo der errado, executar:

```bash
$ comando_rollback
```

---

## Logs e Monitoramento

- Arquivo de log: `/var/log/datalake/operation.log`
- Comando de monitoramento: `tail -f /var/log/...`

---

## Referências

- [docs/20-operations/checklists/](20-operations/checklists/)
- [docs/40-troubleshooting/](40-troubleshooting/)
```

### Checklists - Estrutura Obrigatória

```markdown
# CHECKLIST: [Nome da Checklist]

**Aplicável para:** [Contexto: Prod deployment, Testing, etc.]
**Duração estimada:** XX minutos
**Responsável:** [Role]

---

## Pré-requisitos

- [ ] [Pré-requisito 1]
- [ ] [Pré-requisito 2]
- [ ] [Acesso confirmado a]

---

## Checklist Principal

### Fase 1: Preparação
- [ ] Backup criado em `artifacts/backups/`
- [ ] Notificação enviada ao time
- [ ] Janela de manutenção confirmada

### Fase 2: Execução
- [ ] Parar serviço X
- [ ] Executar migração
- [ ] Validar dados

### Fase 3: Validação
- [ ] Saúde do sistema
- [ ] Logs sem erros
- [ ] Performance dentro do SLA

### Fase 4: Conclusão
- [ ] Comunicar sucesso
- [ ] Documentar problemas (se houver)
- [ ] Agenda revisão pós-implementação

---

## Rollback (Se necessário)

1. Restaurar backup: `restore-backup.sh <backup_id>`
2. Validar sistema
3. Comunicar ao time

---

## Sign-off

- [ ] Executor: _________________________ Data: _____
- [ ] Revisor: _________________________ Data: _____

---

## Referências

- [docs/20-operations/runbooks/](20-operations/runbooks/)
```

### ADRs (Architecture Decision Records)

```markdown
# ADR-20241210-iceberg-catalog-persistence

**Status:** [Proposto | Aceito | Descartado | Supersedido]
**Data:** 2024-12-10
**Autor:** [Nome]
**Reviewers:** [Nomes]

## Contexto

Breve contexto do problema ou oportunidade.

## Problema

Problema específico que estamos resolvendo.

## Soluções Consideradas

### 1. Opção A
- Prós: [lista]
- Contras: [lista]
- Custo: [estimativa]

### 2. Opção B
- Prós: [lista]
- Contras: [lista]

## Decisão

**Escolhida:** Opção [X]

Razões:
1. Justificativa técnica
2. Alinhamento com constraints
3. Impacto em roadmap

## Consequências

### Positivas
- Melhor performance em 30%
- Redução de custo em armazenamento

### Negativas
- Requer migração de dados
- Curva de aprendizado para team

### Neutras
- Não afeta API externa

## Próximos Passos

1. [ ] Implementar spike
2. [ ] Testar em staging
3. [ ] Comunicar ao team
4. [ ] Planejar migração

## Referências

- [Iceberg Catalog Docs](https://iceberg.apache.org/)
- [docs/40-troubleshooting/](40-troubleshooting/) - Problemas conhecidos

---

**Discussão:** [Link para issue/PR](https://github.com/...)
```

## 4. Links Internos

**Formato obrigatório em Markdown:**

```markdown
# ❌ ERRADO
Veja o arquivo CONTEXT.md para mais informações.
Consulte docs/CONTEXT.md

# ✅ CORRETO
Veja [CONTEXT.md](00-overview/CONTEXT.md) para mais informações.
Consulte [docs/CONTEXT.md](00-overview/CONTEXT.md).

# ✅ COM LINHA
Veja [linha 42 de CONTEXT.md](00-overview/CONTEXT.md#L42).

# ✅ EM LISTAS
- [Arquitetura](10-architecture/Projeto.md)
- [Operações](20-operations/runbooks/)
```

**Padrão de path relativo:**
- De `docs/00-overview/README.md` para `docs/CONTEXT.md`: `./CONTEXT.md`
- De `docs/20-operations/runbooks/RUNBOOK_STARTUP.md` para `docs/10-architecture/Projeto.md`: `../../10-architecture/Projeto.md`
- De `infra/provisioning/deploy.sh` para `docs/50-reference/env.md`: `../../docs/50-reference/env.md`

## 5. Código e Exemplos

### Blocos de Código

```markdown
# Python
\`\`\`python
def backup_data():
    return "backup.tar.gz"
\`\`\`

# Bash
\`\`\`bash
#!/bin/bash
set -e
docker compose up -d
\`\`\`

# YAML
\`\`\`yaml
version: '3.8'
services:
  spark:
    image: spark:latest
\`\`\`

# SQL
\`\`\`sql
SELECT * FROM iceberg_table
WHERE date >= '2024-12-01'
\`\`\`
```

### Exemplos de Saída

Use `bash` com `$` para shell:

```bash
$ python test_iceberg.py
Running test...
✅ Test passed
```

## 6. Versionamento de Documentação

### Status de Documento

```
Status: [Draft | Review | Published | Deprecated]
```

- **Draft**: Trabalho em progresso
- **Review**: Pronto para revisão
- **Published**: Aprovado e em produção
- **Deprecated**: Obsoleto, favor usar [novo doc]

### Histórico de Mudanças (Opcional)

```markdown
## Histórico

| Versão | Data | Autor | Mudança |
|--------|------|-------|---------|
| 1.0 | 2024-12-01 | João | Criação inicial |
| 1.1 | 2024-12-05 | Maria | Adicionado troubleshooting |
| 2.0 | 2024-12-10 | João | Reorganização completa |
```

## 7. Processo de PR (Pull Request)

### Checklist para Submeter Doc

- [ ] Arquivo está no diretório correto
- [ ] Nome do arquivo segue convenção
- [ ] Conteúdo segue template/estrutura
- [ ] Links internos testados (existem)
- [ ] Sem credenciais ou secrets
- [ ] Markdown lint pass (sem erros)
- [ ] Atualizado `docs/00-overview/README.md` (índice)
- [ ] Se novo ADR, adicionado a `docs/60-decisions/`
- [ ] Se problema/solução, atualizado `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`

### Exemplo de Commit Message

```
docs: Adicionar RUNBOOK_BACKUP_RESTORE.md

- Adicionado passo-a-passo completo de backup
- Incluído troubleshooting para falhas comuns
- Referências atualizadas em docs/20-operations/

Closes #123
```

## 8. Automatização

### GitHub Actions (Lint de Markdown)

```yaml
name: Lint Documentation
on: [pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: nosborn/github-action-markdown-cli@v3.3.0
        with:
          files: docs/
```

### Script Local (Verificar Links)

```bash
#!/bin/bash
# check-doc-links.sh
find docs -name "*.md" -type f | while read file; do
    echo "Verificando $file..."
    grep -o '\[.*\](' "$file" | grep -v "^http" | while read link; do
        path=$(echo "$link" | sed 's/.*](\(.*\))/\1/')
        if [[ ! -f "$path" ]] && [[ ! -d "$path" ]]; then
            echo "❌ Link quebrado: $path em $file"
        fi
    done
done
```

## 9. Referências Rápidas

- Template ADR: [docs/60-decisions/ADR-template.md](60-decisions/ADR-template.md)
- Problemas conhecidos: [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](40-troubleshooting/PROBLEMAS_ESOLUCOES.md)
- Índice principal: [docs/00-overview/README.md](00-overview/README.md)
- Guia de git: [docs/CONTEXT.md](00-overview/CONTEXT.md)

---

**Dúvidas?** Abra uma issue ou PR para discussão!
