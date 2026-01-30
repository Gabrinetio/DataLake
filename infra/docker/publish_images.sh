#!/bin/bash
set -e

# Configurações do Hub
USERNAME="gabrinetio"

echo "=============================================="
echo "🏗️  Construindo e Publicando Imagens DataLake"
echo "    Usuário: $USERNAME"
echo "=============================================="

# 1. Hive Metastore
echo ""
echo "📦 Processando Hive Metastore..."
HIVETAG="$USERNAME/datalake-hive:1.0.0"
docker compose -f infra/docker/docker-compose.yml build hive-metastore
docker push $HIVETAG
echo "✅ Hive Metastore publicado: $HIVETAG"

# 2. Spark (Base image used by Master/Worker)
echo ""
echo "📦 Processando Apache Spark (Unified Image)..."
SPARKTAG="$USERNAME/datalake-spark:3.5.0"
docker compose -f infra/docker/docker-compose.yml build spark-master
# A imagem base eh a mesma, basta buildar um deles para criar a tag
docker push $SPARKTAG
echo "✅ Apache Spark publicado: $SPARKTAG"

# 3. Superset
echo ""
echo "📦 Processando Apache Superset..."
SUPERTAG="$USERNAME/datalake-superset:3.0.0"
docker compose -f infra/docker/docker-compose.yml build superset
docker push $SUPERTAG
echo "✅ Apache Superset publicado: $SUPERTAG"

echo ""
echo "=============================================="
echo "🚀 Todas as imagens foram publicadas no Docker Hub!"
echo "   Disponível em: https://hub.docker.com/u/$USERNAME"
echo "=============================================="
