# Referências Técnicas - DataLake (Atualizado 12/12/2025)

Este diretório centraliza toda a documentação técnica, autenticação, configurações e mapeamento de infraestrutura do DataLake.

---

## 🔐 AUTENTICAÇÃO PROXMOX (Nova Política - 12/12/2025)

**Status:** ✅ Migração concluída - APENAS autenticação por senha

### Documentos de Autenticação:
- **[PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md)** — Política oficial
- **[IMPLEMENTAR_AUTENTICACAO_SENHA.md](IMPLEMENTAR_AUTENTICACAO_SENHA.md)** — Checklist 22 itens
- **[MUDANCAS_AUTENTICACAO_RESUMO.md](MUDANCAS_AUTENTICACAO_RESUMO.md)** — Resumo de mudanças
- **[QUICK_REF_AUTENTICACAO.md](QUICK_REF_AUTENTICACAO.md)** — Copie e cole pronto
- **[REMOVER_PORT_2222.md](REMOVER_PORT_2222.md)** — Limpeza de Port 2222

---

## 📊 INFRAESTRUTURA MAPEADA (Novo - 12/12/2025)

**Status:** ✅ Todos 8 containers validados e documentados

### Documentos de Infraestrutura:
- **[SUMARIO_EXECUTIVO_INFRAESTRUTURA.md](SUMARIO_EXECUTIVO_INFRAESTRUTURA.md)** — Visão geral executiva
- **[MAPA_CONTAINERS_PROXMOX.md](MAPA_CONTAINERS_PROXMOX.md)** — Inventário de 8 containers
- **[STATUS_POSTGRESQL.md](STATUS_POSTGRESQL.md)** — PostgreSQL (CT 115, CT 116)
- **[MAPA_BANCOS_DADOS.md](MAPA_BANCOS_DADOS.md)** — PostgreSQL + MariaDB completo
- **[REFERENCIA_RAPIDA_COMANDOS.md](REFERENCIA_RAPIDA_COMANDOS.md)** — Comandos essenciais

---

## ✅ TAREFAS CONCLUÍDAS (12/12/2025)

### Relatório:
- **[RELATORIO_CONCLUSAO_LIMPEZA_PROXMOX.md](RELATORIO_CONCLUSAO_LIMPEZA_PROXMOX.md)** — Relatório final de todas as tarefas

### Tarefas Completadas:
- ✅ Port 2222 removido
- ✅ iptables limpo
- ✅ SSH porta 22 validada
- ✅ 8/8 containers acessíveis via pct exec
- ✅ PostgreSQL 2x online (CT 115, CT 116)
- ✅ MariaDB 2x online (CT 117, CT 118)
- ✅ Superset funcionando
- ✅ Airflow funcionando
- ✅ Gitea funcionando

---

## 📚 REFERÊNCIAS TÉCNICAS EXISTENTES

### Configuração e Variáveis
- `env.md` — Credenciais e variáveis de ambiente
- `endpoints.md` — Endpoints de serviços
- `portas_acls.md` — Portas e regras de acesso
- `dns_config.md` — Configuração DNS centralizado (192.168.4.30)
- `credenciais_rotina.md` — Procedimentos para credenciais
- `ips_estaticos.md` — Verificação de IPs estáticos dos containers

### Operacional
- `../20-operations/checklists/ROTATE_CREDENTIALS.md` — Rotação de credenciais
- `../20-operations/runbooks/` — Runbooks operacionais

### Arquitetura
- `../00-overview/CONTEXT.md` — Fonte da verdade técnica
- `../10-architecture/Projeto.md` — Arquitetura do DataLake
- `../QUICK_NAV.md` — Navegação rápida

---

## 🎯 Próximo Passo - Centralização PostgreSQL (Fase 1)

**Objetivo:** Consolidar ambos os PostgreSQL em CT 115

**Benefícios:**
- ✅ Único ponto de gerenciamento
- ✅ Facilitar backups centralizados
- ✅ Economizar recursos (menos PostgreSQL em execução)
- ✅ Simplificar replicação/HA futura

Consulte **[MAPA_BANCOS_DADOS.md](MAPA_BANCOS_DADOS.md)** seção "Fase 1: Centralização" para passos detalhados.

---

## 📞 Suporte Rápido

### Acesso Proxmox
→ [PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md)

### Comandos Rápidos
→ [REFERENCIA_RAPIDA_COMANDOS.md](REFERENCIA_RAPIDA_COMANDOS.md)

### Status Geral
→ [SUMARIO_EXECUTIVO_INFRAESTRUTURA.md](SUMARIO_EXECUTIVO_INFRAESTRUTURA.md)

### Bancos de Dados
→ [MAPA_BANCOS_DADOS.md](MAPA_BANCOS_DADOS.md)

---

## 📈 Estatísticas

**Infraestrutura (12/12/2025):**
- Proxmox Host: 1
- Containers: 8 (todos online)
- PostgreSQL: 2 instâncias
- MariaDB: 2 instâncias
- Aplicações: Superset, Airflow, Gitea (online)
- Disco Total: 139.6G
- Uso de Disco: 32.4G (23%)

