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

