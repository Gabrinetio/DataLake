#!/bin/bash

# Adicionar ou alterar a configuração do Airflow no arquivo airflow.cfg
AIRFLOW_CONFIG_FILE="/opt/airflow/airflow.cfg"

# Alterar o valor da variável "executor" no airflow.cfg
sed -i 's/executor = SequentialExecutor/executor = LocalExecutor/' $AIRFLOW_CONFIG_FILE

echo "Configuração do Airflow atualizada."

