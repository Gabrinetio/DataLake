# Referência Rápida - Comandos Essenciais (12/12/2025)

**Status:** ✅ Infraestrutura mapeada e validada

---

## 🔑 Acesso Proxmox (via Senha)

```powershell
# Test básico
ssh -i 'C:\Users\Gabriel Santana\.ssh\id_ed25519' root@192.168.4.25 'whoami'
# Output: root

# Ou via sshpass (sem chave)
sshpass -p 'SENHA' ssh root@192.168.4.25 'whoami'
```

---

## 📦 Acessar Containers

### CT 107 - MinIO
```bash
ssh root@192.168.4.25 'pct exec 107 -- whoami'
```

### CT 108 - Spark
```bash
ssh root@192.168.4.25 'pct exec 108 -- whoami'
```

### CT 109 - Kafka
```bash
ssh root@192.168.4.25 'pct exec 109 -- whoami'
```

### CT 111 - Trino
```bash
ssh root@192.168.4.25 'pct exec 111 -- whoami'
```

### CT 115 - Superset
```bash
ssh root@192.168.4.25 'pct exec 115 -- whoami'
```

### CT 116 - Airflow
```bash
ssh root@192.168.4.25 'pct exec 116 -- whoami'
```

### CT 117 - Hive Metastore
```bash
ssh root@192.168.4.25 'pct exec 117 -- whoami'
```

### CT 118 - Gitea
```bash
ssh root@192.168.4.25 'pct exec 118 -- whoami'
```

---

## 🗄️ PostgreSQL - Comandos

### CT 115 (Superset) - Listar bancos
```bash
ssh root@192.168.4.25 'pct exec 115 -- su - postgres -c "psql -l"'
```

### CT 115 - Conectar ao banco superset
```bash
ssh root@192.168.4.25 'pct exec 115 -- su - postgres -c "psql superset"'
```

### CT 116 (Airflow) - Listar bancos
```bash
ssh root@192.168.4.25 'pct exec 116 -- su - postgres -c "psql -l"'
```

### CT 116 - Conectar ao banco airflow_db
```bash
ssh root@192.168.4.25 'pct exec 116 -- su - postgres -c "psql airflow_db"'
```

---

## 🗂️ MariaDB - Comandos

### CT 117 (Hive) - Listar bancos
```bash
ssh root@192.168.4.25 'pct exec 117 -- mysql -u root -e "SHOW DATABASES;"'
```

### CT 117 - Listar tabelas metastore
```bash
ssh root@192.168.4.25 'pct exec 117 -- mysql -u root -D metastore -e "SHOW TABLES;"'
```

### CT 118 (Gitea) - Listar bancos
```bash
ssh root@192.168.4.25 'pct exec 118 -- mysql -u root -e "SHOW DATABASES;"'
```

### CT 118 - Listar tabelas gitea
```bash
ssh root@192.168.4.25 'pct exec 118 -- mysql -u root -D gitea -e "SHOW TABLES;"'
```

---

## ⚙️ Airflow (CT 116) - Comandos

### Status Airflow
```bash
ssh root@192.168.4.25 'pct exec 116 -- systemctl status airflow-webserver'
ssh root@192.168.4.25 'pct exec 116 -- systemctl status airflow-scheduler'
```

### Logs Airflow
```bash
ssh root@192.168.4.25 'pct exec 116 -- tail -50 ~/airflow/webserver.log'
ssh root@192.168.4.25 'pct exec 116 -- tail -50 ~/airflow/scheduler.log'
```

### Verificar DAGs
```bash
ssh root@192.168.4.25 'pct exec 116 -- airflow dags list'

### Instalar curl + habilitar systemd scheduler (se aplicável)
```bash
# instala curl
./scripts/ct_install_curl.sh --proxmox root@192.168.4.25 --ct 116

# cria/habilita o unit systemd para o scheduler
./scripts/setup_airflow_systemd.sh --proxmox root@192.168.4.25 --ct 116 --venv /opt/airflow_venv --workdir /home/datalake/airflow

# verificar status e logs
./scripts/airflow_check_scheduler.sh --proxmox root@192.168.4.25 --ct 116
```
```

### Database migrate
```bash
ssh root@192.168.4.25 'pct exec 116 -- airflow db migrate'
```

---

## 🎨 Superset (CT 115) - Comandos

### Status Superset
```bash
ssh root@192.168.4.25 'pct exec 115 -- systemctl status superset'
```

### Verificar versão
```bash
ssh root@192.168.4.25 'pct exec 115 -- superset version'
```

### Upgrade banco Superset
```bash
ssh root@192.168.4.25 'pct exec 115 -- superset db upgrade'
```

---

## 🌐 Gitea (CT 118) - Comandos

### Status Gitea
```bash
ssh root@192.168.4.25 'pct exec 118 -- systemctl status gitea'
```

### Verificar versão
```bash
ssh root@192.168.4.25 'pct exec 118 -- gitea --version'
```

### Listar repositórios
```bash
ssh root@192.168.4.25 'pct exec 118 -- ls -la /var/lib/gitea/gitea-repositories/'
```

---

## 📊 Monitoramento de Recursos

### Uso de disco em todos CTs
```bash
ssh root@192.168.4.25 'for ct in 107 108 109 111 115 116 117 118; do echo "CT $ct:"; pct exec $ct -- df -h / | tail -1; echo; done'
```

### Uso de memória
```bash
ssh root@192.168.4.25 'pct exec 116 -- free -h'
```

### Processos rodando (Airflow)
```bash
ssh root@192.168.4.25 'pct exec 116 -- ps aux | grep airflow'
```

---

## 🔧 Tarefas Futuras - Centralização PostgreSQL

### 1. Criar usuário airflow em CT 115
```bash
ssh root@192.168.4.25 'pct exec 115 -- su - postgres -c "psql -c \"CREATE USER airflow WITH PASSWORD '\''airflow_password'\'';\""'
```

### 2. Criar banco airflow em CT 115
```bash
ssh root@192.168.4.25 'pct exec 115 -- su - postgres -c "psql -c \"CREATE DATABASE airflow OWNER airflow; GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;\""'
```

### 3. Habilitar acesso remoto em CT 115
```bash
# Editar pg_hba.conf
ssh root@192.168.4.25 'pct exec 115 -- nano /etc/postgresql/15/main/pg_hba.conf'
# Adicionar: host airflow airflow 192.168.4.36/32 md5

# Editar postgresql.conf
ssh root@192.168.4.25 'pct exec 115 -- nano /etc/postgresql/15/main/postgresql.conf'
# Descomenta: listen_addresses = '*'

# Reiniciar PostgreSQL
ssh root@192.168.4.25 'pct exec 115 -- systemctl restart postgresql'
```

### 4. Atualizar airflow.cfg em CT 116
```bash
ssh root@192.168.4.25 'pct exec 116 -- nano /opt/airflow/airflow.cfg'
# Alterar:
# sql_alchemy_conn = postgresql://airflow:airflow_password@192.168.4.37:5432/airflow
```

### 5. Executar migração
```bash
ssh root@192.168.4.25 'pct exec 116 -- airflow db migrate'
```

---

## 📚 Documentação

Todos os comandos e referências estão documentados em:

- [MAPA_CONTAINERS_PROXMOX.md](MAPA_CONTAINERS_PROXMOX.md)
- [STATUS_POSTGRESQL.md](STATUS_POSTGRESQL.md)
- [MAPA_BANCOS_DADOS.md](MAPA_BANCOS_DADOS.md)
- [PROXMOX_AUTENTICACAO.md](PROXMOX_AUTENTICACAO.md)
- [SUMARIO_EXECUTIVO_INFRAESTRUTURA.md](SUMARIO_EXECUTIVO_INFRAESTRUTURA.md)

---

## 🎯 Status Rápido

```
✅ Proxmox: Online
✅ CT 107 (MinIO): Running
✅ CT 108 (Spark): Running
✅ CT 109 (Kafka): Running
✅ CT 111 (Trino): Running
✅ CT 115 (Superset): Running
✅ CT 116 (Airflow): Running
✅ CT 117 (Hive): Running
✅ CT 118 (Gitea): Running
✅ PostgreSQL (2): Online
✅ MariaDB (2): Online
✅ SSH: Porta 22 apenas
```

---

## 💡 Dicas

1. **Usar `-i KEY` ao invés de sshpass:**
   ```bash
   ssh -i 'C:\Users\Gabriel Santana\.ssh\id_ed25519' root@192.168.4.25 'command'
   ```

2. **Usar alias para CTs frequentes:**
   ```bash
   alias ct115='ssh -i KEY root@192.168.4.25 "pct exec 115 --"'
   alias ct116='ssh -i KEY root@192.168.4.25 "pct exec 116 --"'
   ```

3. **Executar múltiplos comandos:**
   ```bash
   ssh root@192.168.4.25 'pct exec 115 -- bash -c "whoami && pwd && ls"'
   ```

4. **Transferir arquivos:**
   ```bash
   # Para container
   scp arquivo.txt root@192.168.4.25:/tmp/
   
   # Dentro do container
   ssh root@192.168.4.25 'pct exec 115 -- cat /tmp/arquivo.txt'
   ```

