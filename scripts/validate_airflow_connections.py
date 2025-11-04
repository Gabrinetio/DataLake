#!/bin/bash

# Ativar o ambiente virtual do Airflow
source /opt/airflow/venv/bin/activate

# Atualizar as dependências
pip install --upgrade pip
pip install -r /opt/airflow/requirements.txt

echo "Dependências do Airflow atualizadas com sucesso."

