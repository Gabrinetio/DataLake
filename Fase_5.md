# Documentação: Fase 5 - Engenharia de Dados (ETL com Airflow)

**Versão:** 1.0  
**Data:** 2 de Novembro de 2025  
**Status:** ✅ **CONCLUÍDO E OPERACIONAL**

---

## 1. Visão Geral

A Fase 5 marca a transição da construção da infraestrutura para a aplicação prática de engenharia de dados. O objetivo principal desta fase foi implementar um pipeline de Extract, Transform, Load (ETL) para processar os dados brutos de churn de clientes e prepará-los para análise e visualização.

O processo foi orquestrado pelo Apache Airflow, lendo dados do bucket `raw-zone` no MinIO, aplicando transformações e carregando o resultado limpo e otimizado no bucket `curated-zone`.

---

## 2. Arquitetura do Pipeline

O fluxo de dados implementado nesta fase é o seguinte:

1. **Extração (Extract):** Um arquivo CSV (`WA_Fn-UseC_-Telco-Customer-Churn.csv`) é lido pelo Airflow a partir do bucket `raw-zone` no MinIO.
2. **Transformação (Transform):** A DAG do Airflow, usando a biblioteca Pandas, realiza a limpeza e o tratamento dos dados. A principal transformação foi a conversão da coluna `TotalCharges` para um formato numérico, tratando valores inconsistentes.
3. **Carga (Load):** Os dados transformados são salvos em formato **Parquet** (um formato colunar otimizado para análise) no bucket `curated-zone` do MinIO com o nome `processed_telco_churn.parquet`.

---

## 3. Implementação da DAG no Airflow

Foi desenvolvida uma DAG específica para orquestrar todo o processo de ETL.

### 3.1. Preparação do Ambiente Airflow

Antes de executar a DAG, foi necessário instalar dependências adicionais no container do Airflow (CT 103).

1. **Acesso ao Container:** `pct enter 103`
2. **Ativação do Ambiente Virtual:** `source /opt/airflow/venv/bin/activate`
3. **Instalação de Pacotes Python:**
   ```bash
   pip install pandas "apache-airflow-providers-amazon>=8.13.0" s3fs pyarrow
   ```
   - `pandas`: Para manipulação e transformação dos dados.
   - `s3fs` & `pyarrow`: Permitem que o Pandas leia e escreva arquivos Parquet diretamente de/para o MinIO.

### 3.2. Código Final da DAG

O script a seguir foi salvo como `process_churn_data_from_raw_to_curated.py` no diretório `/opt/airflow/dags/`.

```python
from __future__ import annotations

import pendulum
import pandas as pd
from io import StringIO

from airflow.decorators import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

@dag(
    dag_id='process_churn_data_from_raw_to_curated',
    schedule=None,
    start_date=pendulum.datetime(2025, 11, 2, tz="America/Sao_Paulo"),
    catchup=False,
    tags=['datalake', 'churn', 'processing'],
    doc_md="""
    ### DAG de Processamento de Dados de Churn

    Esta DAG é responsável por:
    1. Ler um arquivo CSV da `raw-zone` do MinIO.
    2. Aplicar transformações básicas de limpeza.
    3. Salvar o arquivo processado em formato Parquet na `curated-zone`.
    """
)
def process_churn_data():
    """
    ### Pipeline de Processamento de Dados de Churn

    Este pipeline ETL extrai dados da raw-zone, os transforma e carrega na curated-zone.
    """

    @task
    def extract_from_raw_zone(s3_conn_id: str, bucket_name: str, file_key: str) -> str:
        """
        Extrai um arquivo CSV do MinIO (raw-zone) e retorna seu conteúdo como uma string.
        """
        print(f"Iniciando extração do arquivo: {file_key} do bucket: {bucket_name}")
        hook = S3Hook(aws_conn_id=s3_conn_id)
        
        content = hook.read_key(key=file_key, bucket_name=bucket_name)
        
        print("Extração concluída com sucesso.")
        return content

    @task
    def transform_and_load_to_curated(csv_content: str, s3_conn_id: str, bucket_name: str, file_key: str):
        """
        Aplica transformações nos dados e carrega o resultado como Parquet na curated-zone.
        """
        print("Iniciando transformação e carregamento dos dados.")
        
        df = pd.read_csv(StringIO(csv_content))
        df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
        df_cleaned = df.dropna()
        
        print("Dados transformados:")
        print(df_cleaned.head())
        
        print("Convertendo dados para o formato Parquet...")
        parquet_buffer = df_cleaned.to_parquet(engine='pyarrow')
        
        print(f"Iniciando carregamento para: {file_key} no bucket: {bucket_name}")
        hook = S3Hook(aws_conn_id=s3_conn_id)
        hook.load_bytes(
            bytes_data=parquet_buffer,
            key=file_key,
            bucket_name=bucket_name,
            replace=True
        )
        print("Carregamento na curated-zone concluído com sucesso.")

    # --- Definição do fluxo da DAG ---

    RAW_BUCKET = 'raw-zone'
    CURATED_BUCKET = 'curated-zone'
    INPUT_FILE_KEY = 'WA_Fn-UseC_-Telco-Customer-Churn.csv' 
    OUTPUT_FILE_KEY = 'processed_telco_churn.parquet'
    
    raw_data_content = extract_from_raw_zone(
        s3_conn_id='minio_s3_default',
        bucket_name=RAW_BUCKET,
        file_key=INPUT_FILE_KEY
    )
    
    transform_and_load_to_curated(
        csv_content=raw_data_content,
        s3_conn_id='minio_s3_default',
        bucket_name=CURATED_BUCKET,
        file_key=OUTPUT_FILE_KEY
    )

process_churn_data()
```

### 3.3. Desafios Resolvidos

- **Problema de Conectividade:** A tarefa inicial falhou com um erro de `ConnectTimeoutError`. A causa raiz foi a configuração da conexão `minio_s3_default` no Airflow, que apontava para o endereço IP antigo da rede privada (`10.10.10.12`).
  - **Solução:** A conexão foi atualizada na UI do Airflow para usar o nome de domínio correto: `http://minio.gti.local:9000`.
- **Erro de Serialização (XCom):** A tentativa de passar os dados Parquet (em formato `bytes`) entre tarefas do Airflow causou um `TypeError: Object of type bytes is not JSON serializable`.
  - **Solução:** As tarefas de transformação e carga foram combinadas em uma única (`transform_and_load_to_curated`), eliminando a necessidade de passar dados binários via XCom.

---

## 4. Conexão do Superset com os Dados Curados

Com os dados processados e disponíveis, o próximo passo foi conectar a ferramenta de BI, Apache Superset, ao arquivo Parquet no MinIO.

### 4.1. Preparação do Ambiente Superset

A conexão foi estabelecida usando a engine analítica **DuckDB**, que pode ler arquivos Parquet diretamente de armazenamentos compatíveis com S3.

1. **Acesso ao Container:** `pct enter 104`
2. **Ativação do Ambiente Virtual:** `source /opt/superset/venv/bin/activate`
3. **Instalação de Pacotes Python:**
   ```bash
   pip install duckdb "duckdb-engine>=0.9"
   ```
4. **Instalação Manual das Extensões do DuckDB:** O DuckDB tentou baixar automaticamente a extensão `httpfs`, mas falhou devido à falta de um diretório home para o usuário de serviço `superset`.
   - **Solução:** A extensão foi instalada manualmente dentro do ambiente virtual do Superset com o comando:
     ```bash
     /opt/superset/venv/bin/python -c "import duckdb; con = duckdb.connect(); con.execute('INSTALL httpfs; LOAD httpfs; INSTALL s3; LOAD s3;')"
     ```
   - Após a instalação, o serviço do Superset foi reiniciado: `systemctl restart superset.service`.

### 4.2. Configuração da Fonte de Dados no Superset

1. **Criação do Banco de Dados:**
   - Na UI do Superset, em **Data -> Databases**, uma nova conexão foi criada.
   - **Tipo de Banco:** DuckDB
   - **SQLAlchemy URI:** `duckdb:///`

2. **Configuração Avançada:**
   - Na aba **ADVANCED**, dentro de **Engine Parameters**, o seguinte JSON foi adicionado para instruir o DuckDB sobre como se conectar e autenticar no MinIO:
     ```json
     {
         "connect_args": {
             "config": {
                 "s3_endpoint": "minio.gti.local:9000",
                 "s3_use_ssl": false,
                 "s3_url_style": "path",
                 "s3_access_key_id": "admin",
                 "s3_secret_access_key": "sua_senha_super_secreta_para_minio"
             }
         }
     }
     ```

3. **Criação do Dataset Virtual:**
   - Em **Data -> Datasets**, um novo dataset virtual foi criado usando a conexão DuckDB e a seguinte query SQL:
     ```sql
     SELECT * FROM 's3://curated-zone/processed_telco_churn.parquet'
     ```

---

## 5. Estado Final da Fase

Ao final da Fase 5, a plataforma atingiu um marco crucial:

- Um pipeline de ETL automatizável está em produção no Airflow.
- Os dados brutos são transformados e armazenados em um formato otimizado para análise.
- A plataforma de BI (Superset) está conectada com sucesso ao Data Lake, pronta para a criação de dashboards e análises, iniciando a Fase 7.

---

**Próxima Fase:** Fase 6 - Visualização de Dados e Dashboards no Superset.
