# Documentação de Configuração: Container Apache Airflow (CT 103)

**Hostname:** `airflow`  
**IP (LAN):** `192.168.4.53`  
**URL de Acesso:** `http://airflow.gti.local:8080`  
**Finalidade:** Orquestrador de pipelines de dados (ETL/ELT) e ML

## 1. Configuração do Container no Proxmox

- **ID:** 103
- **Hostname:** airflow
- **Template Base:** `debian-12-template`
- **Recursos:** 
  - CPU: 4 Cores
  - RAM: 8 GB
  - Disco: 20 GB

### Configuração de Rede
- **Bridge:** `vmbr0` (Rede Principal/LAN)
- **Tipo:** Estático
- **IP:** `192.168.4.53/24`
- **DNS:** Configurado com IP do servidor DNS local para resolução de domínios `.gti.local`

## 2. Instalação e Configuração

### 2.1. Preparação do Ambiente

**Instalação de dependências do sistema:**
```bash
apt update
apt install -y libpq-dev build-essential python3-venv python3-pip graphviz locales
```

**Configuração de localização (UTF-8):**
```bash
sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
locale-gen
```

### 2.2. Instalação do Airflow

**Criação do ambiente virtual:**
```bash
mkdir -p /opt/airflow/dags
python3 -m venv /opt/airflow/venv
source /opt/airflow/venv/bin/activate
```

**Instalação das bibliotecas:**
```bash
export AIRFLOW_HOME=/opt/airflow
pip install --upgrade pip

AIRFLOW_VERSION=2.8.1
PYTHON_VERSION=3.11
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

pip install \
    "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}" \
    "apache-airflow-providers-amazon" \
    "pandas" \
    "scikit-learn" \
    "pyarrow" \
    "s3fs" \
    "mlflow" \
    "boto3==1.33.13" \
    --constraint "${CONSTRAINT_URL}"
```

### 2.3. Configuração do `airflow.cfg`

**Seção `[core]`:**
```ini
executor = LocalExecutor
sql_alchemy_conn = postgresql+psycopg2://airflow:SENHA_DO_MINIO_AQUI@postgres.gti.local/airflow
load_examples = False
```
> **Importante:** RECOMENDA-SE USAR VARIÁVEL DE AMBIENTE. Nunca versionar senhas reais.

**Seção `[webserver]`:**
```ini
base_url = http://airflow.gti.local:8080
```

### 2.4. Configuração dos Serviços Systemd

**Arquivo: `/etc/systemd/system/airflow-webserver.service`**
```ini
[Unit]
Description=Airflow Webserver
After=network.target postgresql.service

[Service]
User=root
Group=root
Type=simple
Environment="AIRFLOW_HOME=/opt/airflow"
Environment="LANG=en_US.UTF-8"
Environment="LC_ALL=en_US.UTF-8"
Environment="AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags"
ExecStart=/opt/airflow/venv/bin/airflow webserver
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Arquivo: `/etc/systemd/system/airflow-scheduler.service`**
```ini
[Unit]
Description=Airflow Scheduler
After=network.target postgresql.service

[Service]
User=root
Group=root
Type=simple
Environment="AIRFLOW_HOME=/opt/airflow"
Environment="LANG=en_US.UTF-8"
Environment="LC_ALL=en_US.UTF-8"
Environment="AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags"
ExecStart=/opt/airflow/venv/bin/airflow scheduler
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Ativação dos serviços:**
```bash
systemctl daemon-reload
systemctl enable --now airflow-webserver
systemctl enable --now airflow-scheduler
```

## 3. Integração Datalake e MLOps (DAGs)

### 3.1. DAG de ETL: `process_churn_data_from_raw_to_curated`
- **Objetivo:** Ler CSV da `raw-zone`, limpar dados e salvar como Parquet na `curated-zone`
- **Status:** ✅ **Operacional**
- **Método:** Utiliza `S3Hook` do Airflow com conexão `minio_s3_default`

### 3.2. DAG de Treinamento: `train_churn_prediction_model`
- **Objetivo:** Ler Parquet da `curated-zone`, treinar modelo e registrar no MLflow
- **Status:** ✅ **Operacional (com patch)**
- **Desafio:** Falha com `botocore.errorfactory.NoSuchBucket`

### 3.3. Solução: Monkey Patch do Boto3

**Problema:** Versão antiga do `boto3==1.33.13` ignora variáveis de ambiente S3 e tenta conectar ao `s3.amazonaws.com`

**Solução implementada no início da DAG:**
```python
import os
import boto3
from botocore.client import Config

# Credenciais e endpoint
MINIO_ACCESS_KEY = 'admin'
MINIO_SECRET_KEY = 'SENHA_DO_MINIO_AQUI' # RECOMENDA-SE USAR VARIÁVEL DE AMBIENTE
MINIO_ENDPOINT = 'http://192.168.4.52:9000'

# Monkey Patch para boto3 v1.33.13
boto3.setup_default_session(
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
    region_name='us-east-1'
)

# Variáveis de ambiente para Botocore
os.environ['AWS_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['MLFLOW_S3_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['AWS_S3_ADDRESSING_STYLE'] = 'path'
os.environ['AWS_REQUEST_CHECKSUM_CALCULATION'] = 'when_required'
os.environ['AWS_RESPONSE_CHECKSUM_VALIDATION'] = 'when_required'
```
> **Importante:** Troque o valor por seu segredo real APENAS em ambiente seguro e nunca faça commit de segredos reais.

## 4. Verificação e Monitoramento

(...restante do conteúdo permanece igual...)