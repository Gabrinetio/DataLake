# Status PostgreSQL - Validação 12/12/2025

**Data:** 12 de dezembro de 2025  
**Status:** ✅ Centralização concluída (Airflow em CT 115) – CT 116 pronto para descomissionar PostgreSQL

---

## 📊 Resumo PostgreSQL

| CT | Hostname | PostgreSQL | Versão | Bancos | Status |
|----|----------|-----------|---------|--------|--------|
| **115** | superset | Ativo | 15.14 | superset, airflow | ✅ Running (centralizado) |
| **116** | airflow | Ativo | 15.14 | airflow_db | ⚠️ Legado (pode remover na Fase 2) |

---

## 🗄️ CT 115 - Superset (PostgreSQL)

### Configuração
```
Container: 115
Hostname: superset
IP: 192.168.4.37
PostgreSQL: 15.14
Status: active (exited)
Modo: Instalação local (agora também hospeda Airflow)
```

### Bancos de Dados
```
postgres     | Owner: postgres
superset     | Owner: postgres  <- Banco de Superset
airflow      | Owner: airflow   <- Banco do Airflow (centralizado)
template0    | Owner: postgres
template1    | Owner: postgres
```

### Acesso
```bash
# Conectar ao PostgreSQL
pct exec 115 -- su - postgres -c "psql"

# Conectar ao banco superset
pct exec 115 -- su - postgres -c "psql superset"

# Verificar usuários
pct exec 115 -- su - postgres -c "psql -c '\du'"
```

### Status do Serviço
```
● postgresql.service - PostgreSQL RDBMS
  Loaded: loaded (/lib/systemd/system/postgresql.service; enabled)
  Active: active (exited) since Fri 2025-12-12 12:41:49 UTC; 3h 5min ago
```

---

## 🗄️ CT 116 - Airflow (PostgreSQL)

### Configuração
```
Container: 116
Hostname: airflow
IP: 192.168.4.36
PostgreSQL: 15.14
Status: active (exited)
Modo: Instalação local (pode ser removido na Fase 2)
```

### Bancos de Dados
```
airflow_db   | Owner: postgres  <- Banco de Airflow (legado, vazio após migração)
postgres     | Owner: postgres
template0    | Owner: postgres
template1    | Owner: postgres
```

### Acesso
```bash
# Conectar ao PostgreSQL
pct exec 116 -- su - postgres -c "psql"

# Conectar ao banco airflow_db
pct exec 116 -- su - postgres -c "psql airflow_db"

# Verificar usuários
pct exec 116 -- su - postgres -c "psql -c '\du'"
```

### Status do Serviço
```
● postgresql.service - PostgreSQL RDBMS
  Loaded: loaded (/lib/systemd/system/postgresql.service; enabled)
  Active: active (exited) since Fri 2025-12-12 13:44:29 UTC; 2h 2min ago
```

### Airflow Status
```
Webserver: ✅ Ativo
  - PID: 1010, 1012, workers
  - Status: running
  - Memória: ~100-110MB por gunicorn worker

Scheduler: ✅ Ativo
  - PID: 1292, 1296
  - Status: running
  - Memória: ~108-113MB
  - Tempo ligado: 9:59 (desde ontem)
```

---

## 🔍 Verificação Técnica

### PostgreSQL 15.14 em Ambos os Containers
```bash
# CT 115
$ psql --version
psql (PostgreSQL) 15.14 (Debian 15.14-0+deb12u1)

# CT 116
$ psql --version
psql (PostgreSQL) 15.14 (Debian 15.14-0+deb12u1)
```

### Serviços Ativas
```
CT 115 (Superset):
- PostgreSQL ✅ (centralizado superset + airflow)
- Superset (não verificado diretamente)

CT 116 (Airflow):
- PostgreSQL ⚠️ (legado, pode remover)
- Airflow Webserver ✅ (gunicorn)
- Airflow Scheduler ✅
```

---

## 📋 Próximos Passos - Centralização PostgreSQL (Status Final)

### Estado
- ✅ Airflow migrado para CT 115 (banco airflow centralizado)
- ✅ Acesso remoto configurado (pg_hba.conf + postgresql.conf)
- ✅ Migrations executadas (42 tabelas criadas)
- ✅ SQLite removido de CT 116
- ⚠️ PostgreSQL em CT 116 agora é legado (airflow_db vazio)

### Próximas ações recomendadas
1) Monitorar por 48h: CPU/Mem/latência no CT 115
2) Fase 2 (opcional): remover PostgreSQL do CT 116 (liberar recursos)
3) Manter backups regulares apenas no CT 115

---

## 📞 Referências

- [CONTEXT.md](../00-overview/CONTEXT.md)
- [Projeto.md](../10-architecture/Projeto.md)
- [MAPA_CONTAINERS_PROXMOX.md](MAPA_CONTAINERS_PROXMOX.md)

