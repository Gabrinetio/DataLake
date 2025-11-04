# -*- coding: utf-8 -*-
from __future__ import annotations
import pendulum
from airflow.decorators import dag, task

import os
import pandas as pd
import mlflow
import mlflow.sklearn
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score

# --- O FIX DEFINITIVO (Boto3 Monkey Patch para v1.33.13) ---
import boto3

# Credenciais agora são obtidas das variáveis de ambiente (NUNCA em texto!)
MINIO_ACCESS_KEY = os.environ.get('MINIO_ACCESS_KEY')
MINIO_SECRET_KEY = os.environ.get('MINIO_SECRET_KEY')
MINIO_ENDPOINT = os.environ.get('MINIO_ENDPOINT')
MLFLOW_SERVER_URI = os.environ.get('MLFLOW_SERVER_URI')

# --- Aplicar o patch globalmente no boto3 ---
boto3.setup_default_session(
    aws_access_key_id=MINIO_ACCESS_KEY,
    aws_secret_access_key=MINIO_SECRET_KEY,
    region_name='us-east-1'
)
os.environ['AWS_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['MLFLOW_S3_ENDPOINT_URL'] = MINIO_ENDPOINT
os.environ['AWS_S3_ADDRESSING_STYLE'] = 'path'
os.environ['AWS_REGION'] = 'us-east-1'
os.environ['AWS_REQUEST_CHECKSUM_CALCULATION'] = 'when_required'
os.environ['AWS_RESPONSE_CHECKSUM_VALIDATION'] = 'when_required'
# --- Fim do patch ---

@dag(
    dag_id='train_churn_prediction_model',
    schedule=None,
    start_date=pendulum.datetime(2025, 11, 2, tz="America/Sao_Paulo"),
    catchup=False,
    tags=['ml', 'churn', 'training', 'patch_v2'],
    doc_md="""
    ### DAG de Treinamento do Modelo de Churn (VERSAO PATCHED v2)

    Esta DAG aplica um 'monkey patch' na sessao padrao do Boto3
    (com sintaxe para v1.33) e define as variaveis de ambiente
    para forcar o MLflow client (Boto3 v1.33.13) a usar o MinIO.
    """
)
def train_churn_model_dag_patched_v2():
    @task
    def train_and_register_model() -> str:
        """
        Executa o ciclo completo de carregamento de dados, treino
        e registro do modelo no MLflow.
        """

        # Define o servidor de tracking
        mlflow.set_tracking_uri(MLFLOW_SERVER_URI)
        mlflow.set_experiment("predicao_churn_telco")

        # --- 2. Carregamento dos Dados ---
        s3_uri = "s3://curated-zone/processed_telco_churn.parquet"

        print(f"Lendo dados de: {s3_uri}")
        # O Pandas/s3fs ira usar o Boto3 patchado ou as storage_options
        df = pd.read_parquet(
            s3_uri,
            storage_options={
                "key": MINIO_ACCESS_KEY,
                "secret": MINIO_SECRET_KEY,
                "client_kwargs": {
                    "endpoint_url": MINIO_ENDPOINT
                }
            }
        )
        print("Dados carregados com sucesso.")

        # --- 3. Pre-processamento ---
        df['Churn'] = df['Churn'].apply(lambda x: 1 if x == 'Yes' else 0)
        df = df.drop(columns=['customerID'])
        X = df.drop('Churn', axis=1)
        y = df['Churn']
        numeric_features = X.select_dtypes(include=['int64', 'float64']).columns
        categorical_features = X.select_dtypes(include=['object']).columns
        preprocessor = ColumnTransformer(
            transformers=[
                ('num', StandardScaler(), numeric_features),
                ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)])
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

        # --- 4. Treinamento e Tracking com MLflow ---
        with mlflow.start_run() as run:
            print("Iniciando uma nova execucao no MLflow...")
            params = {'C': 0.1, 'solver': 'liblinear', 'random_state': 42}
            mlflow.log_params(params)
            model_pipeline = Pipeline(steps=[('preprocessor', preprocessor),
                                             ('classifier', LogisticRegression(**params))])
            model_pipeline.fit(X_train, y_train)
            y_pred = model_pipeline.predict(X_test)
            accuracy = accuracy_score(y_test, y_pred)
            mlflow.log_metric("accuracy", accuracy)

            # Esta chamada agora ira usar a sessao Boto3 que nos 'patchamos'
            mlflow.sklearn.log_model(model_pipeline, "churn_prediction_model")
            print("Modelo registrado com sucesso no MLflow.")
            return run.info.run_id

    train_and_register_model()

train_churn_model_dag_patched_v2()
