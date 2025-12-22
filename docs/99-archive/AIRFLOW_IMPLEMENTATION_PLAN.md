# 📋 PLANO DE IMPLEMENTAÇÃO: Apache Airflow 2.9.3

**Data de Criação:** 11 de dezembro de 2025  
**Status:** 📋 DOCUMENTADO E PRONTO PARA EXECUÇÃO  
**Container:** CT 116 (airflow.gti.local - 192.168.4.32)

---

## 🎯 Objetivo

Instalar e configurar o **Apache Airflow 2.9.3** como orquestrador central da plataforma DataLake, responsável por:

- ✅ Orquestração de pipelines Spark (batch/streaming)
- ✅ Execução de jobs SQL via Trino
- ✅ Ingestão de dados via Kafka
- ✅ Manutenção de tabelas Iceberg
- ✅ Data Quality checks
- ✅ Integração com GitOps (Gitea)

---

## 📊 Infraestrutura

### Container Airflow
| Item | Valor |
|------|-------|
| **Container ID** | CT 116 |
| **Hostname** | airflow.gti.local |
| **IP** | 192.168.4.32 |
| **SO** | Debian 12 |
| **vCPU** | 2 |
| **RAM** | 4 GB |
| **Disco** | 20 GB SSD |
| **Usuário** | datalake |
| **Porta Web** | 8089 |

---

## 📋 Plano de Implementação (Passo-a-Passo)

### **FASE 1: Preparação do Container** (Tempo: 10 min)

#### 1.1 Criar Container no Proxmox
```bash
# No host Proxmox
pct create 116 debian-12-standard_12.0-1_amd64.tar.zst \
  -hostname airflow.gti.local \
  -cores 2 \
  -memory 4096 \
  -swap 2048 \
  -rootfs local:0,size=20G \
  -net0 name=eth0,bridge=vmbr0,ip=192.168.4.32/24,gw=192.168.4.1 \
  -unprivileged 1 \
  -nesting 1

pct start 116
```

#### 1.2 Configurar Acesso SSH
```bash
# SSH para o container
ssh datalake@192.168.4.32

# Ou via Proxmox
pct exec 116 bash
```

#### 1.3 Instalar Pré-requisitos
```bash
apt update && apt upgrade -y
apt install -y python3 python3-venv python3-pip python3-dev build-essential \
  openssl libssl-dev libffi-dev libpq-dev curl wget git vim postgresql-client

# Criar usuário
adduser datalake
usermod -aG sudo datalake

# Verificar versão Python
python3 --version  # Deve ser 3.11+
```

---

### **FASE 2: Instalação do Airflow** (Tempo: 30 min)

#### 2.1 Criar Ambiente Virtual
```bash
sudo mkdir -p /opt/airflow_venv
sudo chown datalake:datalake /opt/airflow_venv

python3 -m venv /opt/airflow_venv
source /opt/airflow_venv/bin/activate
```

#### 2.2 Instalar Airflow 2.9.3
```bash
# Ativar venv
source /opt/airflow_venv/bin/activate

# Instalar Airflow com constraints
pip install --upgrade pip setuptools wheel

pip install "apache-airflow==2.9.3" \
  --constraint https://raw.githubusercontent.com/apache/airflow/constraints-2.9.3/constraints-2.9.3.txt
```

#### 2.3 Instalar Providers (Conectores)
```bash
source /opt/airflow_venv/bin/activate

pip install \
  apache-airflow-providers-apache-spark==4.2.0 \
  apache-airflow-providers-apache-kafka==1.4.0 \
  apache-airflow-providers-trino==5.6.0 \
  apache-airflow-providers-amazon==8.17.0 \
  apache-airflow-providers-postgres==5.10.0
```

#### 2.4 Criar Diretórios
```bash
mkdir -p /opt/airflow
mkdir -p /opt/airflow/dags
mkdir -p /opt/airflow/logs
mkdir -p /opt/airflow/plugins
mkdir -p /opt/airflow/data

sudo chown -R datalake:datalake /opt/airflow
sudo chmod -R 755 /opt/airflow
```

---

### **FASE 3: Configuração do Airflow** (Tempo: 20 min)

#### 3.1 Inicializar Banco de Dados
```bash
source /opt/airflow_venv/bin/activate
export AIRFLOW_HOME=/opt/airflow

airflow db init
```

#### 3.2 Criar Usuário Admin (Credenciais Seguras)
```bash
source /opt/airflow_venv/bin/activate
export AIRFLOW_HOME=/opt/airflow

# Gerar senha aleatória forte (mínimo 32 caracteres, alphanumeric + special chars)
# Use um gerador: openssl rand -base64 24
# Ou crie manualmente: X9kL#mP2@nQ7$vR4&sT1%wU8

ADMIN_PASSWORD="Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3"

airflow users create \
  --username admin \
  --firstname Airflow \
  --lastname Administrator \
  --role Admin \
  --email admin@gti.local \
  --password "$ADMIN_PASSWORD"

# 📌 GUARDAR ESSA SENHA EM LUGAR SEGURO!
# Use um gerenciador de senhas (Vault, 1Password, Bitwarden, etc.)
```

#### 3.3 Configurar airflow.cfg
```bash
# Editar arquivo de configuração
nano /opt/airflow/airflow.cfg
```

**Alterações Importantes:**

```ini
# WEBSERVER
web_server_port = 8089
base_url = http://airflow.gti.local:8089
web_server_host = 0.0.0.0
# Produção: usar HTTPS + proxy reverso
# base_url = https://airflow.gti.local/

# EXECUTOR
executor = LocalExecutor
# Produção: usar CeleryExecutor + Redis para distributed execution
# executor = CeleryExecutor
# broker_url = redis://redis.gti.local:6379/0
# result_backend = postgresql+psycopg2://airflow_user:SENHA@db-hive.gti.local:5432/airflow_celery

# DATABASE (PostgreSQL) - PRODUÇÃO
sql_alchemy_conn = postgresql+psycopg2://airflow_user:$(echo $AIRFLOW_DB_PASSWORD)@db-hive.gti.local:5432/airflow_db

# DIRETÓRIOS
dags_folder = /opt/airflow/dags
base_log_folder = /opt/airflow/logs
plugins_folder = /opt/airflow/plugins

# SEGURANÇA (PRODUÇÃO)
fernet_key = $(echo $FERNET_KEY)  # Usar variável de ambiente!
expose_config = False
rbac = True
auth_backend = airflow.contrib.auth.backends.ldap_auth  # Produção: LDAP/OAuth2
authenticate = True
authentication_provider = airflow.providers.http.auth.kerberos_auth

# WEBSERVER AUTH (Produção)
webserver_config_file = /opt/airflow/webserver_config.py

# LOGGING
log_level = INFO
max_log_age_in_days = 30
# Produção: centralizar em ELK/Loki
# remote_logging = True
# remote_log_conn_id = s3_logs

# AGENDAMENTO
catchup_by_default = False
dag_dir_list_interval = 300

# ALERTAS E SLA (Produção)
slack_conn_id = slack_default
email_backend = airflow.providers.email.backends.smtp.SendGridEmailBackend
smtp_host = smtp.sendgrid.net
smtp_port = 587
smtp_user = apikey
smtp_password = $(echo $SENDGRID_API_KEY)

# RATE LIMITING (Produção)
[core]
max_active_dag_runs_per_dag = 1
max_active_tasks_per_dag = 10
parallelism = 32
dag_concurrency = 16
```

#### 3.4 Gerar Fernet Key (Segurança)
```bash
source /opt/airflow_venv/bin/activate

python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Copiar resultado e adicionar ao airflow.cfg como fernet_key
```

#### 3.5 Configurar Gerenciamento de Segredos com HashiCorp Vault (PRODUÇÃO)

**Por quê Vault?**
- ✅ Centraliza todas as credenciais
- ✅ Rotação automática de senhas
- ✅ Auditoria de acessos
- ✅ Integração nativa com Airflow
- ✅ Suporta dynamic credentials

**Instalação e Configuração Rápida:**

```bash
# 1. Instalar Vault (já disponível em CT 115 conforme docs)
# curl https://releases.hashicorp.com/vault/1.15.0/vault_1.15.0_linux_amd64.zip -o vault.zip
# unzip vault.zip && sudo mv vault /usr/local/bin

# 2. Inicializar Vault
vault server -dev  # Modo desenvolvimento (NÃO produção!)

# 3. Em outro terminal, fazer login
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="s.your_root_token_here"

# 4. Criar políticas e secrets
vault policy write airflow - << EOF
path "secret/data/airflow/*" {
  capabilities = ["read", "list"]
}
path "secret/data/spark/*" {
  capabilities = ["read"]
}
path "secret/data/kafka/*" {
  capabilities = ["read"]
}
path "secret/data/minio/*" {
  capabilities = ["read"]
}
path "secret/data/trino/*" {
  capabilities = ["read"]
}
path "secret/data/postgres/*" {
  capabilities = ["read"]
}
EOF

# 5. Gerar token para Airflow
vault token create -policy=airflow -ttl=8760h
# Copiar token_value → usar como AIRFLOW_VAR_VAULT_TOKEN

# 6. Adicionar secrets ao Vault
vault kv put secret/spark/default token="Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6"
vault kv put secret/kafka/sasl password="Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1"
vault kv put secret/minio/spark \
  access_key="datalake_prod" \
  secret_key="Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6"
vault kv put secret/trino/airflow password="Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3"
vault kv put secret/postgres/hive password="Qw3$Et7@mK5%nL2&pS9*rT4#uV1!xY6"
```

**Configurar Airflow para usar Vault:**

```bash
# 1. Instalar provider Vault
source /opt/airflow_venv/bin/activate
pip install apache-airflow-providers-hashicorp

# 2. Adicionar ao airflow.cfg
[secrets]
backend = airflow.providers.hashicorp.secrets.vault.VaultBackend
backend_kwargs = {
    "connections_path": "secret/airflow/connections",
    "variables_path": "secret/airflow/variables",
    "mount_point": "secret",
    "kv_version": 2,
    "jwt_exp_secs": 3600,
    "jwt_exp_delta_secs": 3600,
    "role_id": "airflow_role",
    "secret_id": "airflow_secret"
}

# 3. Variáveis de ambiente
export VAULT_ADDR="http://vault.gti.local:8200"
export VAULT_TOKEN="hvs.CAESIGxxxxxxxxxxxxxxxxxxxxxxxxx"
export AIRFLOW_VAR_VAULT_ENABLED="true"
```

**Alternativa: AWS Secrets Manager**

```bash
# Se usando AWS em vez de Vault
pip install apache-airflow-providers-amazon

# Configurar airflow.cfg
[secrets]
backend = airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend
backend_kwargs = {
    "connections_prefix": "airflow/connections",
    "variables_prefix": "airflow/variables",
    "region_name": "us-east-1"
}
```

**Alternativa: Variáveis de Ambiente (Simples)**

```bash
# Para desenvolvimento/testes rápidos
# Não recomendado para produção!

export AIRFLOW_CONN_SPARK_DEFAULT="spark://spark_user:Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6@spark.gti.local:7077"
export AIRFLOW_CONN_MINIO_DEFAULT="s3://datalake_prod:Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6@192.168.4.32:9000"
export AIRFLOW_CONN_KAFKA_DEFAULT="kafka://datalake:Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1@kafka.gti.local:9093"

# Usar em airflow.cfg
[core]
# ... outras configurações
```

**Políticas de Rotação de Credenciais:**

```bash
# Script para rotar senhas mensalmente
cat > /opt/airflow/scripts/rotate_credentials.sh << 'EOF'
#!/bin/bash

# Gerar novas senhas aleatórias (32 caracteres, alta entropia)
SPARK_NEW_PASS=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
KAFKA_NEW_PASS=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
MINIO_NEW_PASS=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
TRINO_NEW_PASS=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
POSTGRES_NEW_PASS=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)

# Atualizar no Vault
vault kv put secret/spark/default token="$SPARK_NEW_PASS"
vault kv put secret/kafka/sasl password="$KAFKA_NEW_PASS"
vault kv put secret/minio/spark secret_key="$MINIO_NEW_PASS"
vault kv put secret/trino/airflow password="$TRINO_NEW_PASS"
vault kv put secret/postgres/hive password="$POSTGRES_NEW_PASS"

echo "✅ Credenciais rotacionadas com sucesso!"
echo "📋 Nova senha Spark: $SPARK_NEW_PASS"
# ... salvar em lugar seguro, e.g., 1Password/Bitwarden

# Agendar via cron
# 0 2 1 * * /opt/airflow/scripts/rotate_credentials.sh
EOF

chmod +x /opt/airflow/scripts/rotate_credentials.sh
```

---

### **FASE 4: Configurar Conexões** (Tempo: 15 min)

#### 4.1 Spark Connection (com autenticação)
```bash
source /opt/airflow_venv/bin/activate
export AIRFLOW_HOME=/opt/airflow

# PRODUÇÃO: Usar variáveis de ambiente ou Vault para credenciais
export SPARK_AUTH_TOKEN=$(vault kv get -field=token secret/spark/default || echo "")

airflow connections add 'spark_default' \
  --conn-type 'spark' \
  --conn-host 'spark.gti.local' \
  --conn-port '7077' \
  --conn-login 'spark_user' \
  --conn-password "${SPARK_AUTH_TOKEN}" \
  --conn-extra '{
    "queue": "default",
    "deploy_mode": "cluster",
    "spark_binary": "/opt/spark/spark-3.5.7-bin-hadoop3/bin/spark-submit",
    "timeout": "300"
  }'

# NOTA: Em produção, usar Vault, AWS Secrets Manager ou variáveis de ambiente
# Exemplo Vault: vault kv put secret/spark/default token="Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6"
```

#### 4.2 Kafka Connection (com SASL/TLS)
```bash
# PRODUÇÃO: Kafka com SASL e TLS
export KAFKA_PASSWORD=$(vault kv get -field=password secret/kafka/sasl || echo "")

airflow connections add 'kafka_default' \
  --conn-type 'kafka' \
  --conn-host 'kafka.gti.local' \
  --conn-port '9093' \
  --conn-login 'datalake' \
  --conn-password "${KAFKA_PASSWORD}" \
  --conn-extra '{
    "security.protocol": "SASL_SSL",
    "sasl.mechanism": "PLAIN",
    "ssl.ca.location": "/etc/ssl/certs/kafka-ca.pem",
    "ssl.certificate.location": "/etc/ssl/certs/kafka-client.pem",
    "ssl.key.location": "/etc/ssl/private/kafka-client-key.pem",
    "client.id": "airflow",
    "group.id": "airflow_consumers"
  }'

# SETUP VAULT:
# vault kv put secret/kafka/sasl password="Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1"
```

#### 4.3 MinIO / S3 Connection (credenciais em Vault)
```bash
# PRODUÇÃO: Acessar credenciais do Vault, NÃO hardcoding
export MINIO_ACCESS_KEY=$(vault kv get -field=access_key secret/minio/spark || echo "spark_user")
export MINIO_SECRET_KEY=$(vault kv get -field=secret_key secret/minio/spark || echo "")

airflow connections add 'minio_default' \
  --conn-type 's3' \
  --conn-host '192.168.4.32' \
  --conn-port '9000' \
  --conn-login "${MINIO_ACCESS_KEY}" \
  --conn-password "${MINIO_SECRET_KEY}" \
  --conn-extra '{
    "aws_access_key_id": "'${MINIO_ACCESS_KEY}'",
    "aws_secret_access_key": "'${MINIO_SECRET_KEY}'",
    "host": "192.168.4.32:9000",
    "region_name": "us-east-1",
    "s3_config_format": "uri",
    "s3_endpoint_url": "http://192.168.4.32:9000",
    "ssl_verify": false
  }'

# SETUP VAULT:
# vault kv put secret/minio/spark access_key="datalake_prod" secret_key="Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6"
```

#### 4.4 Trino Connection (com TLS)
```bash
# PRODUÇÃO: Trino com TLS e LDAP
export TRINO_PASSWORD=$(vault kv get -field=password secret/trino/airflow || echo "")

airflow connections add 'trino_default' \
  --conn-type 'trino' \
  --conn-host 'trino.gti.local' \
  --conn-port '8443' \
  --conn-login 'airflow_user' \
  --conn-password "${TRINO_PASSWORD}" \
  --conn-extra '{
    "https": true,
    "ssl_verify": "/etc/ssl/certs/trino-ca.pem",
    "catalog": "iceberg",
    "schema": "warehouse",
    "user_impersonation_enabled": false,
    "timeout": "300"
  }'

# SETUP VAULT:
# vault kv put secret/trino/airflow password="Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3"
```

#### 4.5 PostgreSQL (Hive Metastore) Connection (credenciais seguras)
```bash
# PRODUÇÃO: Acessar senha do Vault
export HIVE_DB_PASSWORD=$(vault kv get -field=password secret/postgres/hive || echo "")

airflow connections add 'postgres_hive' \
  --conn-type 'postgres' \
  --conn-host 'db-hive.gti.local' \
  --conn-port '5432' \
  --conn-login 'hive_user' \
  --conn-password "${HIVE_DB_PASSWORD}" \
  --conn-schema 'metastore' \
  --conn-extra '{
    "sslmode": "require",
    "connect_timeout": "10",
    "options": "-c default_transaction_isolation=read_committed",
    "pool_size": "10",
    "pool_recycle": "3600"
  }'

# SETUP VAULT:
# vault kv put secret/postgres/hive password="Qw3$Et7@mK5%nL2&pS9*rT4#uV1!xY6"
```

---

### **FASE 5: Criar Serviços Systemd** (Tempo: 10 min)

#### 5.1 Serviço Webserver
```bash
sudo cat > /etc/systemd/system/airflow-webserver.service << 'EOF'
[Unit]
Description=Airflow Webserver
After=network.target postgresql.service

[Service]
Type=simple
User=datalake
Group=datalake
WorkingDirectory=/opt/airflow
Environment="AIRFLOW_HOME=/opt/airflow"
Environment="PATH=/opt/airflow_venv/bin:$PATH"
ExecStart=/opt/airflow_venv/bin/airflow webserver --port 8089
Restart=on-failure
RestartSec=5
StandardOutput=append:/opt/airflow/logs/webserver.log
StandardError=append:/opt/airflow/logs/webserver.log

[Install]
WantedBy=multi-user.target
EOF
```

#### 5.2 Serviço Scheduler
```bash
sudo cat > /etc/systemd/system/airflow-scheduler.service << 'EOF'
[Unit]
Description=Airflow Scheduler
After=network.target postgresql.service airflow-webserver.service

[Service]
Type=simple
User=datalake
Group=datalake
WorkingDirectory=/opt/airflow
Environment="AIRFLOW_HOME=/opt/airflow"
Environment="PATH=/opt/airflow_venv/bin:$PATH"
ExecStart=/opt/airflow_venv/bin/airflow scheduler
Restart=on-failure
RestartSec=5
StandardOutput=append:/opt/airflow/logs/scheduler.log
StandardError=append:/opt/airflow/logs/scheduler.log

[Install]
WantedBy=multi-user.target
EOF
```

#### 5.3 Iniciar Serviços
```bash
sudo systemctl daemon-reload
sudo systemctl enable airflow-webserver airflow-scheduler
sudo systemctl start airflow-webserver airflow-scheduler

# Verificar status
sudo systemctl status airflow-webserver
sudo systemctl status airflow-scheduler
```

---

### **FASE 6: Validação e Testes** (Tempo: 15 min)

#### 6.1 Verificar Status
```bash
# Webserver rodando
curl -s http://airflow.gti.local:8089 | head -20

# Scheduler ativo
source /opt/airflow_venv/bin/activate
export AIRFLOW_HOME=/opt/airflow
airflow health

# DAGs carregados
airflow dags list
```

#### 6.2 Acessar Web UI
```
http://airflow.gti.local:8089
Usuário: admin
Senha: Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3
```

**Verificar:**
- ✅ DAGs aparecem (inicialmente vazia)
- ✅ Admin → Connections (aparecem as 5 conexões)
- ✅ Scheduler Status = healthy
- ✅ Logs carregando

#### 6.3 DAG Simples de Teste
```bash
cat > /opt/airflow/dags/test_dag.py << 'EOF'
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def hello_world():
    print("✅ Airflow está funcionando!")

with DAG(
    dag_id="test_dag",
    start_date=datetime(2025, 1, 1),
    schedule_interval="@once",
    catchup=False
):
    task1 = PythonOperator(
        task_id="hello_task",
        python_callable=hello_world
    )
EOF

# Recarregar DAGs
airflow dags reparse
airflow dags list | grep test_dag
```

---

### **FASE 7: Integração com Spark** (Tempo: 20 min)

#### 7.1 DAG de Teste Spark → Iceberg
```bash
cat > /opt/airflow/dags/spark_iceberg_pipeline.py << 'EOF'
from airflow import DAG
from airflow.providers.apache.spark.operators.spark_submit import SparkSubmitOperator
from datetime import datetime

with DAG(
    dag_id="spark_to_iceberg",
    start_date=datetime(2025, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    tags=["spark", "iceberg"]
):
    spark_job = SparkSubmitOperator(
        task_id="process_to_iceberg",
        application="/opt/datalake/jobs/process_to_iceberg.py",
        conn_id="spark_default",
        conf={
            "spark.iceberg.catalog": "iceberg",
            "spark.iceberg.warehouse": "s3a://datalake/warehouse"
        }
    )
EOF
```

#### 7.2 Job Spark Correspondente
```bash
cat > /opt/datalake/jobs/process_to_iceberg.py << 'EOF'
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("iceberg_processor") \
    .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.iceberg.type", "hive") \
    .config("spark.sql.catalog.iceberg.uri", "thrift://db-hive.gti.local:9083") \
    .getOrCreate()

# Processar dados
df = spark.range(1000).selectExpr("id", "concat('data_', id) as value")

# Gravar em Iceberg
df.write \
    .mode("overwrite") \
    .option("path", "s3a://datalake/warehouse/test_table") \
    .format("iceberg") \
    .saveAsTable("iceberg.default.test_data")

print("✅ Dados gravados em Iceberg!")
spark.stop()
EOF
```

---

## 🔧 Monitoramento e Troubleshooting

### Verificar Logs
```bash
# Webserver
tail -f /opt/airflow/logs/webserver.log

# Scheduler
tail -f /opt/airflow/logs/scheduler.log

# DAGs específicas
tail -f /opt/airflow/logs/spark_to_iceberg/
```

### Reiniciar Serviços
```bash
sudo systemctl restart airflow-webserver airflow-scheduler
```

### Limpar Cache
```bash
source /opt/airflow_venv/bin/activate
export AIRFLOW_HOME=/opt/airflow

airflow dags reparse
airflow webserver --reset-db  # ⚠️ CUIDADO - apaga todas as configurações!
```

---

## 📊 Próximos Passos (Após Implementação)

1. ✅ **Criar DAGs Operacionais**
   - Ingestão Kafka → MinIO
   - Processamento MinIO → Iceberg
   - Limpeza de dados
   - Data Quality checks

2. ✅ **Configurar Alertas**
   - SLA de pipelines
   - Email notifications
   - Slack integration

3. ✅ **Integração GitOps**
   - Sincronizar DAGs com Gitea
   - CI/CD para deployer DAGs
   - Versionamento de código

4. ✅ **Escalabilidade**
   - Migrar para CeleryExecutor com Redis
   - Configurar Workers distribuídos
   - Load balancing

5. ✅ **Observabilidade**
   - Prometheus metrics
   - Grafana superset.gti.locals
   - Centralizar logs

---

## ✅ Checklist de Validação

- [ ] Container 116 criado e online
- [ ] Pré-requisitos instalados
- [ ] Airflow 2.9.3 instalado
- [ ] Banco PostgreSQL configurado
- [ ] Usuário admin criado
- [ ] 5 conexões configuradas
- [ ] Serviços systemd ativos
- [ ] Web UI acessível em :8089
- [ ] DAG de teste carrega
- [ ] Conexão Spark funcionando
- [ ] Logs sendo criados
- [ ] Scheduler em "healthy"

---

## 📌 Referências

- Documentação Completa: `/docs/Projeto.md` (Capítulo 9)
- Configuração: `/opt/airflow/airflow.cfg`
- DAGs: `/opt/airflow/dags/`
- Logs: `/opt/airflow/logs/`

---

**Tempo Total Estimado:** 2-3 horas (primeiro setup)  
**Data Recomendada:** Após Spark (CT 108) estar 100% operacional  
**Próximo Componente:** Superset (CT 115) ou Gitea (repositório)

---

**Criado em:** 11 de dezembro de 2025  
**Status:** 📋 PRONTO PARA IMPLEMENTAÇÃO







