#!/bin/bash

# Script de testes do MinIO

echo "=== Testes do MinIO ==="

# Testar console
curl -I http://minio.gti.local:9001

# Configurar mc se necessário
mc alias set minio http://minio.gti.local:9000 datalake 'iRB;g2&ChZ&XQEW!'

# Listar buckets
mc ls minio

# Criar arquivo de teste
echo 'teste MinIO' > /tmp/test_minio.txt
mc cp /tmp/test_minio.txt minio/datalake/tmp/test_minio.txt

# Ler arquivo
mc cat minio/datalake/tmp/test_minio.txt

echo "Testes concluídos. Verifique se 'teste MinIO' foi retornado."