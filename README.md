# 🏗️ DataLake FB - Apache Spark + Iceberg

> **Plataforma de Data Lake moderna com Apache Spark 4.0.1, Apache Iceberg 1.10.0 e time-travel capabilities.**

**Status:** ✅ 100% Funcional | **Docs:** 📚 Reorganizadas | **Atualizado:** 11 dez 2025

---

## 🚀 Começando

| Situação | Ação |
|----------|------|
| **Novo no projeto?** | Leia [COMECE_AQUI.md](./COMECE_AQUI.md) (5 min) |
| **Precisa entender tudo?** | Consulte [DOCUMENTACAO.md](./DOCUMENTACAO.md) |
| **Procurando algo específico?** | Veja [docs/QUICK_NAV.md](./docs/QUICK_NAV.md) |
| **Encontrou erro?** | Consulte [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](./docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md) |

---

## 📚 Documentação

A documentação está organizada em **16 diretórios temáticos** dentro de [`docs/`](./docs/):

```
docs/
├── 00-overview/           ← Visão geral & contexto
├── 10-architecture/       ← Arquitetura técnica
├── 20-operations/         ← Runbooks & checklists
├── 30-iterations/         ← Planos & resultados
├── 40-troubleshooting/    ← Problemas & soluções
├── 50-reference/          ← Endpoints, portas, credenciais
├── 60-decisions/          ← ADRs (decisões técnicas)
├── 99-archive/            ← Histórico
├── CONTRIBUTING.md        ← Como contribuir
└── QUICK_NAV.md           ← Navegação por cenário
```

Acesso rápido:
- **Contexto & Decisões:** [docs/00-overview/CONTEXT.md](./docs/00-overview/CONTEXT.md)
- **Arquitetura:** [docs/10-architecture/Projeto.md](./docs/10-architecture/Projeto.md)
- **Operações:** [docs/20-operations/runbooks/](./docs/20-operations/runbooks/)
- **Referências:** [docs/50-reference/](./docs/50-reference/)

---

## 🏗️ Stack Técnico

| Componente | Versão |
|-----------|--------|
| Apache Spark | 4.0.1 |
| Apache Iceberg | 1.10.0 |
| Hive Metastore | 3.x |
| MinIO | Latest |
| Python | 3.11.2 |
| Java | 17+ |

---

## 📁 Estrutura do Projeto

```
DataLake_FB-v2/
├── docs/              ← 📚 Documentação (16 diretórios)
├── infra/             ← ⚙️  Scripts de deploy, provisioning, libs
├── src/               ← 💻 Código e testes
├── artifacts/         ← 📊 Resultados e logs
├── .env               ← Configuração (não versionar dados sensíveis)
├── README.md          ← Este arquivo
└── COMECE_AQUI.md     ← Guia rápido
```

---

## ✨ Destaques

✅ **Time Travel & Snapshots** — Recupere dados de qualquer ponto no tempo  
✅ **Data Governance** — Rastreamento completo de alterações com Iceberg  
✅ **Backup & Restore** — RTO < 2 minutos, RPO próximo a zero  
✅ **Security Hardening** — 23 políticas de segurança implementadas  
✅ **100% Automatizado** — Scripts prontos para deploy em produção  

---

## 🔍 Validação & Testes

Para validar a integridade da documentação:

```bash
# PowerShell
pwsh -NoProfile -File docs/check-doc-links.ps1 -DocsDir "docs"

# Ou Bash
bash docs/check-doc-links.sh docs/
```

---

## 📞 Suporte Rápido

| Problema | Solução |
|----------|---------|
| **Erros comuns?** | [docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md](./docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md) |
| **Como deployar?** | [docs/20-operations/checklists/](./docs/20-operations/checklists/) |
| **Preciso entender a arquitetura?** | [docs/10-architecture/Projeto.md](./docs/10-architecture/Projeto.md) |
| **Variáveis de ambiente?** | [docs/50-reference/env.md](./docs/50-reference/env.md) |
| **Como contribuir?** | [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md) |

---

## 🎯 Roadmap

- ✅ **Iteração 5** — 100% Completo (Time Travel, Iceberg, Security)
- 🔄 **Iteração 6** — CDC Integration + RLAC + BI  
- 📅 **Iteração 7** — Advanced Analytics + Performance Tuning

---

**Versão:** 2.0 | **Atualizado:** 11 dez 2025 | **Manutenedor:** DataLake Team

