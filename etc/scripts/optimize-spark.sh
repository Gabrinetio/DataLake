#!/bin/bash

# 🚀 Iteração 6 - FASE 1: Performance Optimization
# Script: optimize-spark.sh
# Data: 9 de dezembro de 2025

echo "🚀 INICIANDO OTIMIZAÇÃO SPARK - ITERAÇÃO 6"
echo "=========================================="

SPARK_HOME="/opt/spark/spark-3.5.7-bin-hadoop3"
SPARK_CONF="$SPARK_HOME/conf"

# Criar backup das configurações atuais
echo "📋 Criando backup das configurações atuais..."
cp $SPARK_CONF/spark-defaults.conf $SPARK_CONF/spark-defaults.conf.backup.$(date +%Y%m%d_%H%M%S)
cp $SPARK_CONF/spark-env.sh $SPARK_CONF/spark-env.sh.backup.$(date +%Y%m%d_%H%M%S)

echo "✅ Backup criado"

# Configurações otimizadas para CT 109
echo "⚙️ Aplicando configurações otimizadas..."

cat > $SPARK_CONF/spark-defaults.conf << 'EOF'
# Spark Performance Optimization - Iteração 6
# Data: 9 de dezembro de 2025

# Memory Configuration
spark.driver.memory                 4g
spark.executor.memory               4g
spark.executor.cores                2
spark.default.parallelism           8
spark.sql.shuffle.partitions        8
spark.iceberg.shuffle.num-partitions 8

# Adaptive Query Execution
spark.sql.adaptive.enabled           true
spark.sql.adaptive.skewJoin.enabled  true
spark.sql.adaptive.coalescePartitions.enabled true
spark.sql.adaptive.coalescePartitions.minPartitionNum 1
spark.sql.adaptive.coalescePartitions.initialPartitionNum 8

# Statistics & CBO
spark.sql.statistics.histogram.enabled true
spark.sql.cbo.enabled               true
spark.sql.cbo.joinReorder.enabled    true

# Iceberg Optimizations
spark.iceberg.split.planning.open-file-cost 4194304
spark.iceberg.write.parquet.compression-codec snappy
spark.iceberg.write.parquet.row-group-size-bytes 134217728
spark.iceberg.write.target-file-size-bytes 536870912

# Performance Tuning
spark.serializer                     org.apache.spark.serializer.KryoSerializer
spark.kryo.registrator               org.apache.iceberg.spark.data.SparkKryoRegistrator
spark.sql.inMemoryColumnarStorage.compressed true
spark.sql.inMemoryColumnarStorage.batchSize 10000

# Network & I/O
spark.shuffle.compress               true
spark.shuffle.spill.compress         true
spark.broadcast.compress             true
spark.rdd.compress                  true

# Logging
spark.eventLog.enabled              true
spark.eventLog.dir                  /opt/spark/logs/events
EOF

echo "✅ Configurações Spark aplicadas"

# Otimizar spark-env.sh
echo "🔧 Otimizando spark-env.sh..."

cat >> $SPARK_CONF/spark-env.sh << 'EOF'

# Performance Optimizations - Iteração 6
export SPARK_DAEMON_MEMORY=1g
export SPARK_WORKER_MEMORY=4g
export SPARK_WORKER_CORES=2

# Java Options
export SPARK_MASTER_OPTS="-Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
export SPARK_WORKER_OPTS="-Xmx2g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Network
export SPARK_LOCAL_IP=192.168.4.33
EOF

echo "✅ spark-env.sh otimizado"

# Criar diretório de logs se não existir
mkdir -p /opt/spark/logs/events

echo ""
echo "🎯 OTIMIZAÇÃO SPARK COMPLETA!"
echo "=============================="
echo "📊 Configurações aplicadas:"
echo "   - Memory: 4GB driver/executor"
echo "   - Cores: 2 por executor"
echo "   - Partitions: 8 (shuffle + Iceberg)"
echo "   - Adaptive Query: ENABLED"
echo "   - CBO: ENABLED"
echo "   - Compression: Snappy"
echo ""
echo "🔄 Próximo passo: Reiniciar Spark Master"
echo "   Comando: /opt/spark/sbin/stop-master.sh && /opt/spark/sbin/start-master.sh"
echo ""
echo "✅ Script concluído com sucesso!"