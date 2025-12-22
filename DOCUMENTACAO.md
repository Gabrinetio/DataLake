# DataLake FB - Documentação

**Organização Completa & Simplificada | 11 de dezembro de 2025**

---

## 🚀 Começar Aqui

| Cenário | Ação |
|---------|------|
| **Novo no projeto?** | Leia [docs/QUICK_NAV.md](./docs/QUICK_NAV.md) |
| **Entender arquitetura?** | Consulte [docs/00-overview/CONTEXT.md](./docs/00-overview/CONTEXT.md) |
| **Como operar?** | Veja [docs/20-operations/](./docs/20-operations/) |
| **Contribuir docs?** | Siga [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md) |
| **Troubleshooting?** | Acesse [docs/40-troubleshooting/](./docs/40-troubleshooting/) |

---

## 📚 Documentação

**Estrutura de 16 diretórios organizados por função:**

```
docs/
├── 00-overview/              ← Visão geral, índices, CONTEXT
├── 10-architecture/          ← Arquitetura do projeto
├── 20-operations/            ← Runbooks e checklists
├── 30-iterations/            ← Planos e resultados por iteração
├── 40-troubleshooting/       ← Problemas e soluções
├── 50-reference/             ← Variáveis, endpoints, portas
├── 60-decisions/             ← ADRs (decisões arquiteturais)
├── 99-archive/               ← Histórico e documentação legada
├── CONTRIBUTING.md           ← Padrões de contribuição
├── QUICK_NAV.md              ← Navegação rápida
└── check-doc-links.ps1       ← Validador de links
```

---

## ✅ Atualizações Recentes

**11 de dezembro de 2025:**
- ✅ Reorganização completa de 16 diretórios
- ✅ 25+ documentos reorganizados
- ✅ 6 scripts atualizados com novos paths
- ✅ Automação CI/CD implementada
- ✅ Scripts de validação de links (PowerShell + Bash)
- ✅ Documentação consolidada e simplificada

**Relatório completo:** [REORGANIZACAO_RELATORIO_FINAL.md](./REORGANIZACAO_RELATORIO_FINAL.md)

---

## 🔧 Ferramentas

### Validar Links de Documentação
```powershell
pwsh -NoProfile -File docs/check-doc-links.ps1 -DocsDir "docs"
```

### Contribuir com Documentação
1. Leia [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md)
2. Use templates em [docs/60-decisions/](./docs/60-decisions/)
3. Valide links antes de submeter

---

## 📖 Índices Disponíveis

| Índice | Propósito |
|--------|-----------|
| [docs/00-overview/README.md](./docs/00-overview/README.md) | Índice centralizado novo |
| [docs/00-overview/CONTEXT.md](./docs/00-overview/CONTEXT.md) | Contexto técnico completo |
| [docs/QUICK_NAV.md](./docs/QUICK_NAV.md) | Navegação por cenários |
| [docs/REORGANIZACAO_SUMMARY.md](./docs/REORGANIZACAO_SUMMARY.md) | Mapa de migração |

---

## 🎯 Status

```
✅ Reorganização: 100% concluída
✅ Scripts: Atualizados
✅ Documentação: Consolidada
✅ Validação: Automatizada
🟢 PRONTO PARA PRODUÇÃO
```

---

**Última Atualização:** 11 de dezembro de 2025  
**Documentação:** [docs/](./docs/)  
**Relatório:** [REORGANIZACAO_RELATORIO_FINAL.md](./REORGANIZACAO_RELATORIO_FINAL.md)
