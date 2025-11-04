Com certeza. O seu resumo está excelente.

Eu consolidei o seu resumo com o arquivo `CT_Airflow.md` original, atualizei todas as informações de rede (IPs, Hostnames) com base no seu `README.md` e `Fase_5.md`, e destaquei a solução final do "Monkey Patch" do Boto3 que descobrimos.

Aqui está a documentação atualizada e completa para o **Container Apache Airflow (CT 103)**.

-----

# Documentação de Configuração: Container Apache Airflow (CT 103)

**Hostname:** `airflow`  
**IP (LAN):** `192.168.4.53`  
**URL de Acesso:** `http://airflow.gti.local:8080`  
**Finalidade:** Orquestrador de pipelines de dados (ETL/ELT) e ML.

-----

## 1\. Configuração do Container (CT) no Proxmox

  * **ID:** 103
  * **Hostname:** airflow
  * **Recursos:** 4 Cores, 8 GB RAM, 20 GB Disco
  * **Template Base:** `debian-12-template`
  * **Rede (`net0`):**
      * **Bridge:** `vmbr0` (Rede Principal/LAN)
      * **Tipo:** Estático
      * **Endereço IP:** `192.168.4.53/24`
      * **Gateway:** (Gateway da sua rede local)
  * **DNS (em Options):** Configurado com o IP do seu servidor DNS local para resolver os domínios `.gti.local`.

-----

## 2\. Passos de Instalação e Configuração

### 2.1. Preparação do Ambiente do Container

1.  **Instalação de Dependências de Sistema:**
    ```bash
    apt update
    apt install -y libpq-dev build-essential python3-venv python3-pip graphviz locales
    ```
2.  **Configuração de Localização (Locale) para Suporte a UTF-8:**
    *Este passo é **crítico** para evitar erros de `UnicodeEncodeError`.*
    ```bash
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen
    locale-gen
    ```

### 2.2. Instalação do Airflow e Dependências do Pipeline

1.  **Criação do Ambiente Virtual:**
    ```bash
    mkdir -p /opt/airflow/dags
    python3 -m venv /opt/airflow/venv
    source /opt/airflow/venv/bin/activate
    ```
2.  **Instalação das Bibliotecas (Ambiente Isolado):**
    ```bash
    export AIRFLOW_HOME=/opt/airflow
    pip install --upgrade pip

    AIRFLOW_VERSION=2.8.1 # Exemplo de versao
    PYTHON_VERSION=3.11 # Inferido do seu sistema
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

    # Instalar Airflow core, provedores e todas as bibliotecas do projeto
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
    *Nota: A versão do `boto3==1.33.13` foi a versão estável identificada que funciona com as dependências do Airflow (ex: `aiobotocore`).*

### 2.3. Configuração do `airflow.cfg`

Após a primeira execução de `airflow db init`, o arquivo `$AIRFLOW_HOME/airflow.cfg` foi editado:

  * **Seção `[core]`:**
    ```ini
    executor = LocalExecutor
    sql_alchemy_conn = postgresql+psycopg2://airflow:[SUA_SENHA_POSTGRES]@postgres.gti.local/airflow
    load_examples = False
    ```
  * **Seção `[webserver]`:**
    ```ini
    base_url = http://airflow.gti.local:8080
    ```

### 2.4. Configuração dos Serviços `systemd`

Os arquivos de serviço (`airflow-webserver.service` e `airflow-scheduler.service`) foram configurados para incluir variáveis de ambiente essenciais para a codificação e descoberta de DAGs.

**Exemplo de Configuração (ex: `airflow-webserver.service`):**

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
ExecStart=/opt/airflow/venv/bin/airflow webserver --port 8080
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

*(O `airflow-scheduler.service` é idêntico, mas usa `ExecStart=/opt/airflow/venv/bin/airflow scheduler`)*

-----

## 3\. Integração Datalake e MLOps (DAGs)

O CT 103 hospeda as duas DAGs principais do pipeline no diretório `/opt/airflow/dags`.

### 3.1. DAG de ETL (process\_churn\_data\_from\_raw\_to\_curated)

  * **Objetivo:** Ler o CSV da `raw-zone`, limpar os dados (ex: `TotalCharges`) e salvar como Parquet na `curated-zone`.
  * **Status:** ✅ **Operacional.**
  * **Método de Conexão:** Esta DAG usa o `S3Hook` do Airflow. O `S3Hook` lê com sucesso a conexão `minio_s3_default` (configurada na UI do Airflow), que contém o `endpoint_url` no campo "Extra", e por isso **funciona corretamente**.

### 3.2. DAG de Treinamento (train\_churn\_prediction\_model)

  * **Objetivo:** Ler o Parquet da `curated-zone`, treinar um modelo de ML e registá-lo no MLflow (CT 105), que por sua vez salva o artefato no MinIO (CT 102).
  * **Status:** ✅ **Operacional (com patch).**
  * **Desafio (Resolvido):** A DAG falhava consistentemente com `botocore.errorfactory.NoSuchBucket`.
  * **Causa Raiz:** A função `mlflow.sklearn.log_model()` (executada no CT 103) chama internamente o `boto3==1.33.13`. Esta versão antiga do `boto3` **ignora** as variáveis de ambiente S3 (como `AWS_ENDPOINT_URL`) e tenta ligar-se ao `s3.amazonaws.com`. Como o container não tem internet, a ligação falha e reporta o falso erro `NoSuchBucket`.

### 3.3. Solução: "Monkey Patch" do Boto3 na DAG de ML

Para corrigir a DAG de ML, foi necessário aplicar um "monkey patch" no início do arquivo `dag_train_churn_model.py` (no CT 103). Este patch força a sessão padrão do Boto3 (v1.33.13) a usar as credenciais e o endpoint corretos do MinIO *antes* que o `mlflow` a utilizasse.

**Código do Patch (Início da DAG de ML):**

```python
# --- INICIO DA DAG 'train_churn_prediction_model.py' ---
import os
import boto3 # Importar boto3 no inicio
from botocore.client import Config

# Definir credenciais e endpoint
MINIO_ACCESS_KEY = 'admin'
MINIO_SECRET_KEY = '[SUA_SENHA_MINIO]' 
MINIO_ENDPOINT = 'http://192.168.4.52:9000'
MLFLOW_SERVER_URI = 'http://mlflow.gti.local:5000'

# --- APLICAR O PATCH GLOBALMENTE NO BOTO3 (SINTAXE ANTIGA) ---
# Forca a sessao padrao do Boto3 (v1.33.13) a usar estas credenciais
boto3.setup_default_session(
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
    region_name='us-east-1'
)

# Definir as variaveis de ambiente que o Botocore (interno do Boto3) le
os.environ['AWS_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['MLFLOW_S3_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['AWS_S3_ADDRESSING_STYLE'] = 'path'
os.environ['AWS_REGION'] = 'us-east-1'
os.environ['AWS_REQUEST_CHECKSUM_CALCULATION'] = 'when_required'
os.environ['AWS_RESPONSE_CHECKSUM_VALIDATION'] = 'when_required'
# --- FIM DO PATCH ---

# ... (import pandas, mlflow, etc.) ...
# ... (Restante do código da DAG de ML) ...
```

O `pandas.read_parquet` também foi configurado para usar `storage_options` explícitas para garantir a leitura:

```python
df = pd.read_parquet(
    "s3://curated-zone/processed_telco_churn.parquet",
    storage_options={
        "key": "[SEU_USUARIO_MINIO]",
        "secret": "[SUA_SENHA_MINIO]",
        "client_kwargs": {"endpoint_url": "http://192.168.4.52:9000"}
    }
)
```

-----

## 4\. Verificação e Acesso

  * **Acesso à Interface Web:** `http://airflow.gti.local:8080`
  * **Ver logs em tempo real:**
    ```bash
    journalctl -u airflow-webserver -f
    journalctl -u airflow-scheduler -f
    ```
  * **Reiniciar Serviços:**
    ```bash
    systemctl restart airflow-webserver airflow-scheduler
    ```
