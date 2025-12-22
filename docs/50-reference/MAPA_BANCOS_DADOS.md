# Mapa de Bancos de Dados - Validação 12/12/2025

**Data:** 12 de dezembro de 2025  
**Status:** ✅ Todos os bancos de dados online

---

## 📊 Resumo Geral
**Status:** ✅ Centralização PostgreSQL concluída (Airflow no CT 115) – CT 116 pronto para descomissionar PostgreSQL
| Tipo | Container | Versão | Bancos Ativos | Status |
|------|-----------|--------|---------------|--------|
| **PostgreSQL** | CT 115 (Superset) | 15.14 | superset, airflow | ✅ Centralizado |
| **PostgreSQL** | CT 116 (Airflow) | 15.14 | airflow_db | ✅ |
| **PostgreSQL** | CT 116 (Airflow) | 15.14 | airflow_db | ⚠️ Legado (vazio) |
| **MariaDB** | CT 117 (Hive) | 10.11.14 | metastore | ✅ |
| **MariaDB** | CT 118 (Gitea) | 10.11.6 | gitea | ✅ |

---

      Bancos: postgres, superset, airflow, template0, template1

      Owners: superset (postgres), airflow (airflow)
      Porta: 5432 (local)
      Status: ✅ Active
Versão: PostgreSQL 15.14
Hostname: superset
IP: 192.168.4.37
Bancos: postgres, superset, template0, template1
Owner Superset DB: postgres
      Bancos: airflow_db (vazio), postgres, template0, template1
Status: ✅ Active
      Owner Airflow DB: postgres
      Porta: 5432 (local)
      Status: ⚠️ Legado (pode remover na Fase 2)
**Acesso:**
      ├── superset (Banco Superset) ✅
      └── airflow (Banco Airflow centralizado) ✅
pct exec 115 -- su - postgres -c "psql superset"
      └── airflow_db (legado, vazio) ⚠️ – remover na Fase 2
---

**Objetivo:** Consolidar ambos os PostgreSQL em CT 115
```
Versão: PostgreSQL 15.14
Hostname: airflow
IP: 192.168.4.36
Bancos: airflow_db, postgres, template0, template1
Owner Airflow DB: postgres
Porta: 5432 (local)
Status: ✅ Active
```

**Acesso:**
```bash
pct exec 116 -- su - postgres -c "psql -l"
pct exec 116 -- su - postgres -c "psql airflow_db"
```

---

## 🗂️ MariaDB

### CT 117 - Hive Metastore
```
Versão: MariaDB 10.11.14
Hostname: db-hive
IP: 192.168.4.32
Bancos Ativos:
  - information_schema
  - metastore (Hive Metastore)
  - mysql
  - performance_schema
  - sys
User: root
Porta: 3306 (local)
Status: ✅ Active
```
pct exec 117 -- mysql -u root -D metastore -e "SHOW TABLES;"
- [x] Centralizar PostgreSQL em CT 115
- [x] Configurar acesso remoto PostgreSQL
- [x] Migrar Airflow para usar CT 115
- [x] Remover SQLite do Airflow (CT 116)
- [ ] Descomissionar PostgreSQL do CT 116 (opcional Fase 2)

### CT 118 - Gitea
```
Versão: MariaDB 10.11.6
Hostname: Gitea
IP: 192.168.4.26
Bancos Ativos:
  - gitea (Banco Gitea)
  - information_schema
  - mysql
  - performance_schema
  - sys
User: root
Porta: 3306 (local)
Status: ✅ Active
Interface Web: http://192.168.4.26:3000
```

**Acesso:**
```bash
pct exec 118 -- mysql -u root -e "SHOW DATABASES;"
pct exec 118 -- mysql -u root -D gitea -e "SHOW TABLES;"
```

---

## 🌐 Topologia de Dados

```
Proxmox Host (192.168.4.25)
│
├── CT 115 - Superset (192.168.4.37)
│   └── PostgreSQL 15.14
│       ├── superset (Banco Superset) ✅
│       └── (futuro) airflow (para centralizar?)
│
├── CT 116 - Airflow (192.168.4.36)
│   └── PostgreSQL 15.14
│       ├── airflow_db (Banco Airflow) ✅
│       └── (opcional) migrar para CT 115
│
├── CT 117 - Hive Metastore (192.168.4.32)
│   └── MariaDB 10.11.14
│       └── metastore (Hive Metastore) ✅
│
└── CT 118 - Gitea (192.168.4.26)
    └── MariaDB 10.11.6
        └── gitea (Repositório Git) ✅
```

---

## 📋 Planejamento PostgreSQL

### Fase 1: Centralização (Recomendado) - PRÓXIMO PASSO

**Objetivo:** Consolidar ambos os PostgreSQL em CT 115

**Passos:**

1. **Criar usuário airflow em CT 115:**
   ```bash
   ssh root@192.168.4.25 'pct exec 115 -- su - postgres -c "psql"'
   CREATE USER airflow WITH PASSWORD 'airflow_password';
   ```

2. **Criar banco airflow em CT 115:**
   ```bash
   CREATE DATABASE airflow OWNER airflow;
   GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
   ```

3. **Configurar acesso remoto (PostgreSQL em CT 115):**
   ```bash
   # Editar pg_hba.conf
   pct exec 115 -- nano /etc/postgresql/15/main/pg_hba.conf
   # Adicionar: host airflow airflow 192.168.4.36/32 md5
   
   # Editar postgresql.conf
   pct exec 115 -- nano /etc/postgresql/15/main/postgresql.conf
   # Descomenta: listen_addresses = '*'
   
   # Restart PostgreSQL
   pct exec 115 -- systemctl restart postgresql
   ```

4. **Atualizar configuração Airflow em CT 116:**
   ```bash
   pct exec 116 -- nano /opt/airflow/airflow.cfg
   # Alterar:
   # sql_alchemy_conn = postgresql://airflow:airflow_password@192.168.4.37:5432/airflow
   ```

5. **Executar migração de banco:**
   ```bash
   pct exec 116 -- airflow db migrate
   ```

**Benefícios:**
- ✅ Único ponto de gerenciamento (CT 115)
- ✅ Facilita backups centralizados
- ✅ Economiza recursos (menos PostgreSQL em execução)
- ✅ Facilita replicação/HA futura

---

## 🔒 Segurança de Acesso

### PostgreSQL
- **Autenticação:** `peer` (usuários locais) e `trust` (localhost)
- **Acesso Remoto:** NÃO configurado (cada CT tem banco local)
- **Recomendação:** Configurar com senha após centralização

### MariaDB
- **Autenticação:** User `root` sem senha (padrão)
- **Acesso Remoto:** Não verificado
- **Recomendação:** Manter isolado por segurança

---

## 📈 Consumo de Recursos

### PostgreSQL
```
CT 115: ~500MB (PostgreSQL 15.14)
CT 116: ~500MB (PostgreSQL 15.14)
Total: ~1GB
```

**Após Centralização:**
```
CT 115: ~700MB (ambos os bancos)
CT 116: ~200MB (sem PostgreSQL)
Total: ~900MB (economia de 100MB)
```

---

## ✅ Checklist de Validação

- [x] PostgreSQL CT 115 - Status ✅
- [x] PostgreSQL CT 116 - Status ✅
- [x] MariaDB CT 117 - Status ✅
- [x] MariaDB CT 118 - Status ✅
- [x] Banco superset - Existe
- [x] Banco airflow_db - Existe
- [x] Banco metastore (Hive) - Existe
- [x] Banco gitea - Existe
- [ ] Centralizar PostgreSQL em CT 115 (PRÓXIMO)
- [ ] Configurar acesso remoto PostgreSQL
- [ ] Migrar Airflow para usar CT 115

---

## 🚀 Próxima Ação

**Próximo passo recomendado:**

Centralizar PostgreSQL em CT 115 conforme planeja na "Fase 1: Centralização"

Consulte [STATUS_POSTGRESQL.md](STATUS_POSTGRESQL.md) para detalhes completos.

