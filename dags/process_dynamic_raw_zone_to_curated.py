# -*- coding: utf-8 -*-
from __future__ import annotations

import pendulum
import pandas as pd
# BytesIO e a "Gem" para ler arquivos binarios (como XLSX) em memoria
from io import BytesIO
import os

from airflow.decorators import dag, task
from airflow.providers.amazon.aws.hooks.s3 import S3Hook

# --- Constantes do Datalake ---
S3_CONN_ID = 'minio_s3_default'
RAW_BUCKET = 'raw-zone'
CURATED_BUCKET = 'curated-zone'

# Lista de extensoes que a DAG ira processar
PROCESSABLE_EXTENSIONS = ['.csv', '.jsonl', '.xlsx', '.xls']


@dag(
    dag_id='process_dynamic_raw_zone_to_curated',
    schedule=None,
    start_date=pendulum.datetime(2025, 11, 7, tz="America/Sao_Paulo"),
    catchup=False,
    tags=['datalake', 'ingestion', 'dynamic', 'curated', 'excel'],
    doc_md="""
    ### DAG de Ingestao Dinamica (Raw -> Curated) [V2 com Excel]

    Esta DAG e responsavel por:
    1. Listar TODOS os arquivos com extensoes validas (ex: .csv, .jsonl, .xlsx)
       no bucket `raw-zone`.
    2. Iniciar dinamicamente uma task de processamento para CADA arquivo.
    3. Ler o arquivo (CSV, JSONL ou Excel) e salvar como Parquet na `curated-zone`.
    """
)
def process_dynamic_raw_zone_to_curated_v2():
    """
    Pipeline de ETL dinamico que processa multiplos arquivos
    da Raw-Zone para a Curated-Zone.
    """

    @task
    def list_files_to_process(s3_conn_id: str, bucket_name: str) -> list[dict]:
        """
        Lista todos os arquivos no bucket S3 (raw-zone) que correspondem
        as extensoes processaveis.
        """
        print(f"Listando arquivos em: {bucket_name}")
        hook = S3Hook(aws_conn_id=s3_conn_id)
        
        all_keys = hook.list_keys(bucket_name=bucket_name)
        
        files_to_process = []
        if not all_keys:
            print("Nenhum arquivo encontrado.")
            return []

        for key in all_keys:
            # Separa o nome do arquivo e a extensao
            filename, file_ext = os.path.splitext(key)
            
            if file_ext.lower() in PROCESSABLE_EXTENSIONS:
                print(f"Arquivo encontrado: {key} (Tipo: {file_ext})")
                files_to_process.append({
                    "raw_key": key,
                    "curated_key": f"{filename}.parquet", # Novo nome do arquivo
                    "file_type": file_ext.lower() # Normalizar para minusculas
                })
                
        print(f"Total de {len(files_to_process)} arquivos para processar.")
        return files_to_process

    @task
    def process_and_load_file(file_info: dict, s3_conn_id: str, raw_bucket: str, curated_bucket: str):
        """
        Le um arquivo da raw-zone (CSV, JSONL, ou XLSX), o transforma
        e carrega como Parquet na curated-zone.
        """
        raw_key = file_info['raw_key']
        curated_key = file_info['curated_key']
        file_type = file_info['file_type']
        
        print(f"Iniciando processamento de: {raw_key}")
        hook = S3Hook(aws_conn_id=s3_conn_id)
        df = None

        try:
            # --- 1. Extracao (Extract) ---
            # "Gem": E mais seguro ler o fluxo de bytes (byte stream) bruto.
            # Usamos get_key() para obter o objeto S3 e depois lemos os bytes.
            
            s3_object = hook.get_key(key=raw_key, bucket_name=raw_bucket)
            # s3_object_body e agora um fluxo de bytes
            s3_object_body = s3_object.get()['Body']
            
            # --- 2. Transformacao (Transform) ---
            print(f"Transformando dados (Tipo: {file_type})...")
            
            if file_type == '.csv':
                # Pandas pode ler o fluxo de bytes diretamente
                df = pd.read_csv(s3_object_body)
                if 'TotalCharges' in df.columns:
                     df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')

            elif file_type == '.jsonl':
                # 'lines=True' para JSON Lines
                df = pd.read_json(s3_object_body, lines=True)
            
            # --- SECAO PARA EXCEL ---
            elif file_type in ['.xlsx', '.xls']:
                # Usamos o BytesIO para tratar o fluxo de bytes como um "arquivo"
                excel_data = BytesIO(s3_object_body.read())
                df = pd.read_excel(excel_data) 
            
            if df is None:
                print(f"Tipo de arquivo {file_type} nao suportado para {raw_key}.")
                return

            df_cleaned = df.dropna(how='all') # Limpa linhas totalmente vazias
            print(f"Transformacao concluida. {len(df_cleaned)} linhas processadas.")

            # --- 3. Carregamento (Load) ---
            print("Convertendo dados para o formato Parquet...")
            parquet_buffer = df_cleaned.to_parquet(engine='pyarrow', index=False)
            
            print(f"Iniciando carregamento para: {curated_key} no bucket: {curated_bucket}")
            hook.load_bytes(
                bytes_data=parquet_buffer,
                key=curated_key,
                bucket_name=curated_bucket,
                replace=True
            )
            print(f"Carregamento de {curated_key} concluido com sucesso.")

        except Exception as e:
            print(f"ERRO ao processar o arquivo {raw_key}: {e}")
            raise

    # --- Definicao do fluxo da DAG ---
    
    # 1. Lista todos os arquivos CSV, JSONL e XLSX na raw-zone
    list_of_files = list_files_to_process(
        s3_conn_id=S3_CONN_ID,
        bucket_name=RAW_BUCKET
    )
    
    # 2. Mapeamento Dinamico
    # A task 'process_and_load_file' sera executada UMA VEZ PARA CADA
    # arquivo retornado pela task 'list_files_to_process'.
    process_and_load_file.partial(
        s3_conn_id=S3_CONN_ID,
        raw_bucket=RAW_BUCKET,
        curated_bucket=CURATED_BUCKET
    ).expand(
        file_info=list_of_files
    )

# Instancia a DAG
process_dynamic_raw_zone_to_curated_v2()
