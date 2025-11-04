# Documentação de Configuração: Container PostgreSQL (CT 101)

**Hostname:** `postgres`  
**IP (LAN):** `192.168.4.51`  
**DNS:** `postgres.gti.local`  
**Finalidade:** Servidor de Banco de Dados central para metadados das aplicações (Airflow, Superset, MLflow)

## 1. Configuração do Container no Proxmox

- **ID:** 101
- **Hostname:** postgres
- **Template Base:** `debian-12-template`
- **Recursos:**
  - CPU: 2 Cores
  - RAM: 4 GB
  - Disco: 40 GB

### Configuração de Rede
- **Bridge:** `vmbr0` (Rede Principal/LAN)
- **Tipo:** Estático
- **IP:** `192.168.4.51/24`
- **DNS:** Configurado com IP do servidor DNS local para resolução de domínios `.gti.local`

## 2. Instalação e Configuração

### 2.1. Instalação do PostgreSQL

```bash
# Atualizar repositórios
apt update

# Instalar PostgreSQL e pacotes adicionais
apt install -y postgresql postgresql-contrib

# Verificar status do serviço
systemctl status postgresql
```

### 2.2. Criação de Bancos de Dados e Usuários

**Acessar o shell do PostgreSQL:**
```bash
su - postgres -c "psql"
```

**Comandos SQL executados:**
```sql
-- Para Apache Airflow
CREATE DATABASE airflow;
CREATE USER airflow WITH PASSWORD '[SENHA_DO_AIRFLOW]';
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;
ALTER DATABASE airflow OWNER TO airflow;

-- Para Apache Superset
CREATE DATABASE superset;
CREATE USER superset WITH PASSWORD '[SENHA_DO_SUPERSET]';
GRANT ALL PRIVILEGES ON DATABASE superset TO superset;
ALTER DATABASE superset OWNER TO superset;

-- Para MLflow
CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD '[SENHA_DO_MLFLOW]';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
ALTER DATABASE mlflow OWNER TO mlflow;

-- Sair do shell
\q
```

### 2.3. Configuração de Acesso à Rede

**Editar `postgresql.conf`:**
```bash
nano /etc/postgresql/15/main/postgresql.conf
```
```ini
# Alterar para:
listen_addresses = '*'
```

**Editar `pg_hba.conf`:**
```bash
nano /etc/postgresql/15/main/pg_hba.conf
```
```
# Adicionar linha:
host    all             all             192.168.4.0/24          md5
```

### 2.4. Finalização

**Reiniciar serviço:**
```bash
systemctl restart postgresql
```

## 3. Estado Final

### Bancos de Dados Criados
| Serviço | Banco de Dados | Usuário | Finalidade |
| :------ | :------------- | :------ | :---------- |
| Airflow | `airflow` | `airflow` | Metadados de DAGs e execuções |
| Superset | `superset` | `superset` | Metadados de dashboards e usuários |
| MLflow | `mlflow` | `mlflow` | Metadados de experimentos e modelos |

### Configuração de Rede
- **Escuta em:** Todas as interfaces (`*`)
- **Rede permitida:** `192.168.4.0/24`
- **Autenticação:** MD5 (senha)

## 4. Verificação e Monitoramento

### Comandos de Verificação
```bash
# Status do serviço
systemctl status postgresql

# Conexões ativas
su - postgres -c "psql -c 'SELECT datname, usename, client_addr FROM pg_stat_activity;'"

# Listar bancos de dados
su - postgres -c "psql -c '\l'"

# Verificar logs
journalctl -u postgresql -f
tail -f /var/log/postgresql/postgresql-15-main.log
```

### Teste de Conexão Externa
```bash
# De outro container na rede
psql -h postgres.gti.local -U airflow -d airflow -W
```

## 5. Estrutura do Sistema

### Diretórios Principais
```
/var/lib/postgresql/
└── 15/
    └── main/
        ├── base/          # Arquivos de dados dos bancos
        ├── pg_wal/        # Write-Ahead Logs
        └── postgresql.conf
```

### Arquivos de Configuração
- **`/etc/postgresql/15/main/postgresql.conf`** - Configurações principais
- **`/etc/postgresql/15/main/pg_hba.conf`** - Controle de acesso
- **`/var/log/postgresql/postgresql-15-main.log`** - Logs do serviço

## 6. Backup e Manutenção

### Backup Completo
```bash
# Como usuário postgres
su - postgres
pg_dumpall > /var/lib/postgresql/backup_completo.sql
```

### Backup Individual
```bash
pg_dump -h postgres.gti.local -U airflow airflow > backup_airflow.sql
```

### Manutenção do Banco
```bash
# Vacuum e análise
su - postgres -c "psql -c 'VACUUM ANALYZE;'"

# Verificar tamanho dos bancos
su - postgres -c "psql -c 'SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;'"
```

## 7. Integração com Outros Serviços

### Airflow (CT 103)
- **URI:** `postgresql+psycopg2://airflow:[SENHA]@postgres.gti.local/airflow`
- **Armazena:** Metadados de DAGs, tasks, execuções

### Superset (CT 104)
- **URI:** `postgresql+psycopg2://superset:[SENHA]@postgres.gti.local/superset`
- **Armazena:** Dashboards, charts, usuários, permissões

### MLflow (CT 105)
- **URI:** `postgresql+psycopg2://mlflow:[SENHA]@postgres.gti.local/mlflow`
- **Armazena:** Experimentos, runs, parâmetros, métricas

## 8. Comandos Úteis

### Monitoramento em Tempo Real
```bash
# Top de queries
su - postgres -c "psql -c 'SELECT query, state, now() - query_start AS duration FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;'"

# Estatísticas de tabelas
su - postgres -c "psql -c 'SELECT schemaname, relname, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_user_tables;'"
```

### Troubleshooting
```bash
# Verificar conexões bloqueadas
su - postgres -c "psql -c 'SELECT pid, wait_event_type, wait_event, query FROM pg_stat_activity WHERE wait_event_type IS NOT NULL;'"

# Kill processo problemático
su - postgres -c "psql -c 'SELECT pg_terminate_backend(pid);'"
```

## 9. Status do Container

**Status:** ✅ **CONFIGURADO E OPERACIONAL**

- [x] Serviço PostgreSQL ativo
- [x] Bancos de dados criados para todos os serviços
- [x] Usuários e permissões configurados
- [x] Acesso de rede configurado para rede local
- [x] Conexões externas funcionando

---

*Documentação atualizada em: 4 de Novembro de 2025*
