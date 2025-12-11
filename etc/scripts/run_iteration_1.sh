#!/bin/bash

# Script para executar Iteração 1: Testes de Carga e Performance
# Uso: ./run_iteration_1.sh [num_records] [num_products] [num_regions]

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ITERAÇÃO 1: TESTES DE CARGA E PERFORMANCE                 ║"
echo "║ DataLake Spark/Iceberg - Dezembro 2025                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Parâmetros
NUM_RECORDS=${1:-100000}
NUM_PRODUCTS=${2:-1000}
NUM_REGIONS=${3:-50}
SPARK_HOME="/opt/spark/spark-3.5.7-bin-hadoop3"
SERVER="192.168.4.33"

echo "📊 Configurações:"
echo "  Registros de vendas: ${NUM_RECORDS:,}"
echo "  Produtos: ${NUM_PRODUCTS}"
echo "  Regiões: ${NUM_REGIONS}"
echo "  Servidor: $SERVER"
echo ""

# 1. Preparar arquivos no servidor
echo "📁 Copiando scripts para servidor..."
scp test_data_generator.py ${SERVER}:/tmp/
scp test_benchmark.py ${SERVER}:/tmp/
echo "✓ Scripts copiados"
echo ""

# 2. Executar gerador de dados
echo "🔨 Fase 1: Gerando dados de teste..."
echo "-------------------------------------------"
ssh ${SERVER} "cd /tmp && \
${SPARK_HOME}/bin/spark-submit \
    --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0 \
    --master local[4] \
    --executor-memory 2g \
    test_data_generator.py \
    ${NUM_RECORDS} ${NUM_PRODUCTS} ${NUM_REGIONS}"

echo ""
echo "✓ Dados gerados com sucesso"
echo ""

# 3. Executar benchmarks
echo "⚡ Fase 2: Executando benchmarks..."
echo "-------------------------------------------"
ssh ${SERVER} "cd /tmp && \
${SPARK_HOME}/bin/spark-submit \
    --packages org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.10.0 \
    --master local[4] \
    --executor-memory 2g \
    test_benchmark.py"

echo ""
echo "✓ Benchmarks executados"
echo ""

# 4. Copiar resultados
echo "📊 Copiando resultados..."
mkdir -p benchmark_results
scp ${SERVER}:/tmp/benchmark_results.json benchmark_results/
echo "✓ Resultados em: benchmark_results/"
echo ""

# 5. Exibir resumo
echo "╔════════════════════════════════════════════════════════════╗"
echo "║ ✅ ITERAÇÃO 1 CONCLUÍDA COM SUCESSO                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Próximos passos:"
echo "  1. Revisar benchmark_results/benchmark_results.json"
echo "  2. Analisar gargalos identificados"
echo "  3. Otimizar configurações Spark conforme recomendações"
echo "  4. Executar Iteração 2 quando pronto"
echo ""
echo "Para mais detalhes:"
echo "  cat docs/ROADMAP_ITERACOES.md"
echo ""
