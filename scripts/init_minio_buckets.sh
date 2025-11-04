#!/bin/bash

# Definir alias e credenciais para o MinIO
mc alias set localminio http://192.168.4.52:9000 admin 'iRB;g2&ChZ&XQEW!'

# Verificar se o bucket 'raw-zone' e 'curated-zone' existem, caso contrário, criá-los
mc ls localminio || mc mb localminio/raw-zone
mc ls localminio || mc mb localminio/curated-zone

# Verificar se o bucket 'mlflow' existe, caso contrário, criá-lo
mc ls localminio || mc mb localminio/mlflow

echo "Buckets verificados e criados (se necessário)."

