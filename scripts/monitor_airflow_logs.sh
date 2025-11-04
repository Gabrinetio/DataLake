#!/bin/bash

# Configurações de monitoramento
AIRFLOW_LOG_DIR="/opt/airflow/logs"
ALERT_EMAIL="admin@domain.com"

# Monitorar falhas de tarefas
tail -n 100 $AIRFLOW_LOG_DIR/*/*/*.log | grep -i "ERROR" | mail -s "Airflow Task Error Alert" $ALERT_EMAIL

echo "Alertas de erro enviados para $ALERT_EMAIL"

