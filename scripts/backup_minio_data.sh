#!/bin/bash

# Definir alias e credenciais para o MinIO
mc alias set localminio http://192.168.4.52:9000 admin 'iRB;g2&ChZ&XQEW!'

# Definir o bucket de destino de backup
BACKUP_BUCKET="backup-zone"

# Sincronizar os dados do MinIO para o bucket de backup
mc mirror localminio/raw-zone localminio/$BACKUP_BUCKET/raw-zone-backup
mc mirror localminio/curated-zone localminio/$BACKUP_BUCKET/curated-zone-backup
mc mirror localminio/mlflow localminio/$BACKUP_BUCKET/mlflow-backup

echo "Backup concluído com sucesso!"

