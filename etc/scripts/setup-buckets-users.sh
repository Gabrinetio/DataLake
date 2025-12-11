#!/bin/bash

# Script para configurar buckets e usuários no MinIO

set -e

echo "=== Configuração de Buckets e Usuários ==="

# Aguardar MinIO iniciar
sleep 5

# Configurar alias mc

# Criar buckets

# Habilitar versioning

# Criar usuários
mc admin user add minio spark_user SparkPass123! || echo "Usuário spark_user já existe"
mc admin user add minio trino_user TrinoPass123! || echo "Usuário trino_user já existe"
mc admin user add minio airflow_user AirflowPass123! || echo "Usuário airflow_user já existe"

# Criar política para Spark
cat > /tmp/spark_policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
  ]
}
EOF

mc admin policy create minio spark-policy /tmp/spark_policy.json
mc admin policy attach minio spark-policy --user spark_user

# Políticas similares para outros usuários (ajuste conforme necessário)

echo "Buckets e usuários configurados."