# Mapa de Containers Proxmox - Validação 12/12/2025

**Data:** 12 de dezembro de 2025  
**Status:** ✅ Todos os containers acessíveis

---

## 📊 Resumo de Containers

| CT | Nome | Hostname | IP | Status | Disco | Uso |
|----|----|----------|-------|--------|-------|-----|
| **107** | minio | minio | 192.168.4.31 | ✅ Running | 40G | 3% |
| **108** | spark | spark | 192.168.4.33 | ✅ Running | 20G | 53% |
| **109** | kafka | kafka | (sem IP) | ✅ Running | 16G | 29% |
| **111** | Trino | Trino | 192.168.4.35 | ✅ Running | 16G | 42% |
| **115** | superset | superset | 192.168.4.37 | ✅ Running | 7.8G | 29% |
| **116** | airflow | airflow | 192.168.4.36 | ✅ Running | 7.8G | 37% |
| **117** | db-hive | db-hive | 192.168.4.32 | ✅ Running | 16G | 39% |
| **118** | Gitea | Gitea | 192.168.4.26 | ✅ Running | 16G | 10% |

---

## 🔍 Informações Detalhadas

### CT 107 - MinIO (S3 Storage)
```
Hostname: minio
IP: 192.168.4.31
Status: ✅ Running
Disco: 40G (847M usado, 37G disponível - 3%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
```

**Função:** Armazenamento de objetos S3-compatível (MinIO)

---

### CT 108 - Spark (Processamento Distribuído)
```
Hostname: spark
IP: 192.168.4.33
Status: ✅ Running
Disco: 20G (9.8G usado, 8.8G disponível - 53%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
```

**Função:** Spark para processamento distribuído de dados

---

### CT 109 - Kafka (Streaming)
```
Hostname: kafka
IP: (sem configuração de rede reportada)
Status: ✅ Running
Disco: 16G (4.3G usado, 11G disponível - 29%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
```

**Função:** Apache Kafka para streaming e event processing

---

### CT 111 - Trino (SQL Distribuído)
```
Hostname: Trino
IP: 192.168.4.35
Status: ✅ Running
Disco: 16G (6.2G usado, 8.7G disponível - 42%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
```

**Função:** Trino para queries SQL distribuídas

---

### CT 115 - Superset (Visualização BI)
```
Hostname: superset
IP: 192.168.4.37
Status: ✅ Running
Disco: 7.8G (2.2G usado, 5.3G disponível - 29%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
Banco de Dados: PostgreSQL 15 (localhost:5432)
```

**Função:** Apache Superset para visualização e dashboards BI

---

### CT 116 - Airflow (Orquestração)
```
Hostname: airflow
IP: 192.168.4.36
Status: ✅ Running
Disco: 7.8G (2.7G usado, 4.7G disponível - 37%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
Versão: Apache Airflow 2.9.3
Banco de Dados: PostgreSQL 15 (localhost:5432)
```

**Função:** Apache Airflow para orquestração de workflows

---

### CT 117 - Hive Metastore (Banco de Dados Metastore)
```
Hostname: db-hive
IP: 192.168.4.32
Status: ✅ Running
Disco: 16G (5.8G usado, 9.2G disponível - 39%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
```

**Função:** Apache Hive Metastore (banco de dados de metadados)

---

### CT 118 - Gitea (Repositório Git)
```
Hostname: Gitea
IP: 192.168.4.26
Status: ✅ Running
Disco: 16G (1.4G usado, 14G disponível - 10%)
OS: Debian GNU/Linux 12 (bookworm)
Tipo: LXC Container
Banco de Dados: MariaDB
Interface Web: http://192.168.4.26:3000
```

**Função:** Gitea para gerenciamento de repositórios Git

---

## 🌐 Topologia de Rede

```
Proxmox Host (192.168.4.25)
├── CT 107 - MinIO (192.168.4.31)
├── CT 108 - Spark (192.168.4.33)
├── CT 109 - Kafka (sem IP reportado)
├── CT 111 - Trino (192.168.4.35)
├── CT 115 - Superset (192.168.4.37) + PostgreSQL
├── CT 116 - Airflow (192.168.4.36) + PostgreSQL
├── CT 117 - Hive Metastore (192.168.4.32)
└── CT 118 - Gitea (192.168.4.26) + MariaDB
```

---

## 📈 Uso de Recursos

### Disco Total
```
CT 107 (MinIO):      40G  (3% utilizado)
CT 108 (Spark):      20G  (53% utilizado) ⚠️
CT 109 (Kafka):      16G  (29% utilizado)
CT 111 (Trino):      16G  (42% utilizado)
CT 115 (Superset):   7.8G (29% utilizado)
CT 116 (Airflow):    7.8G (37% utilizado)
CT 117 (Hive):       16G  (39% utilizado)
CT 118 (Gitea):      16G  (10% utilizado)
────────────────────────────
Total:              139.6G
```

**⚠️ Atenção:** CT 108 (Spark) está com 53% de disco utilizado

---

## 🔗 Conectividade

Todos os containers estão:
- ✅ **Acessíveis via `pct exec`** do Proxmox host
- ✅ **Online e respondendo**
- ✅ **Com acesso SSH funcional** via Proxmox host
- ✅ **Em rede bridge vmbr0**

### Exemplo de Acesso
```bash
# Acessar CT 107 (MinIO)
ssh root@192.168.4.25 'pct exec 107 -- whoami'

# Acessar CT 118 (Gitea)
ssh root@192.168.4.25 'pct exec 118 -- whoami'

# Executar comando em qualquer CT
ssh root@192.168.4.25 'pct exec <CT> -- <comando>'
```

---

## 📋 Checklist de Validação

- [x] Todos os containers estão rodando
- [x] Todos os containers respondem a pct exec
- [x] Todos têm Debian 12 bookworm instalado
- [x] Acesso SSH via Proxmox host funcional
- [x] Networking configurado (exceto CT 109 sem IP)
- [x] Espaço em disco verificado
- [x] Nenhum container em estado crítico

---

## 🚀 Próximos Passos

1. **Investigar CT 109 (Kafka) - Sem IP**
   - Verificar configuração de rede
   - Validar se é intencional

2. **Monitorar CT 108 (Spark) - 53% Disco**
   - Verificar se necessita limpeza
   - Considerar expansão se padrão se necessário

3. **Prosseguir com Tarefas de PostgreSQL**
   - Centralizar banco em CT 115
   - Reconfigurar CT 116 Airflow
   - Executar airflow db migrate

---

## 📞 Referências

- [CONTEXT.md](../00-overview/CONTEXT.md) — Fonte da verdade
- [Projeto.md](../10-architecture/Projeto.md) — Arquitetura
- [PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md) — Autenticação

