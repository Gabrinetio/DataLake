#!/bin/bash
# Script para iniciar Spark Master no CT 108

SPARK_HOME="/opt/spark/spark-3.5.7-bin-hadoop3"

echo "=========================================="
echo "Iniciando Spark Master"
echo "=========================================="

# 1. Verificar se Spark Home existe
if [ ! -d "$SPARK_HOME" ]; then
    echo "❌ SPARK_HOME ($SPARK_HOME) não encontrado"
    exit 1
fi

# 2. Verificar se spark-submit está disponível
if [ ! -x "$SPARK_HOME/bin/spark-submit" ]; then
    echo "❌ spark-submit não encontrado ou não é executável"
    exit 1
fi

# 3. Criar diretório de logs se não existir
mkdir -p "$SPARK_HOME/logs"
mkdir -p "$SPARK_HOME/logs/events"
mkdir -p "$SPARK_HOME/work"

# 4. Verificar se o Master já está rodando
if pgrep -f "spark.deploy.master.Master" > /dev/null; then
    echo "⚠️  Spark Master já está em execução"
    PID=$(pgrep -f "spark.deploy.master.Master")
    echo "   PID: $PID"
    exit 0
fi

# 5. Iniciar o Spark Master
echo "[1/3] Iniciando Spark Master..."
source /etc/profile
$SPARK_HOME/sbin/start-master.sh

sleep 3

# 6. Verificar se iniciou com sucesso
if pgrep -f "spark.deploy.master.Master" > /dev/null; then
    PID=$(pgrep -f "spark.deploy.master.Master")
    echo "✅ Spark Master iniciado com sucesso (PID: $PID)"
else
    echo "❌ Falha ao iniciar Spark Master"
    echo "Verifique os logs:"
    tail -20 "$SPARK_HOME/logs/spark--org.apache.spark.deploy.master.Master-1-spark.gti.local.out"
    exit 1
fi

# 7. Exibir informações
echo ""
echo "=========================================="
echo "Spark Master Ativo"
echo "=========================================="
echo ""
echo "Web UI: http://spark.gti.local:8080"
echo "Master URL: spark://spark.gti.local:7077"
echo ""
echo "Para adicionar Workers:"
echo "  /opt/spark/sbin/start-workers.sh"
echo ""
echo "Para visualizar logs:"
echo "  tail -f $SPARK_HOME/logs/spark--org.apache.spark.deploy.master.Master-1-spark.gti.local.out"
echo ""
