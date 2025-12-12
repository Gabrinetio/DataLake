#!/bin/bash
# Script de teste da integração Spark + Iceberg + Hive Metastore + MinIO

echo "=========================================="
echo "Teste de Integração Spark + Iceberg"
echo "=========================================="

SPARK_HOME="/opt/spark/spark-3.5.7-bin-hadoop3"
source /etc/profile

# Teste 1: Conectividade com Hive Metastore
echo "[1/3] Testando conectividade com Hive Metastore..."
if nc -zv db-hive.gti.local 9083 2>&1 | grep -q "succeeded"; then
    echo "✅ Hive Metastore (9083) acessível"
else
    echo "⚠️  Hive Metastore pode não estar acessível"
fi

# Teste 2: Conectividade com MinIO
echo "[2/3] Testando conectividade com MinIO..."
if nc -zv minio.gti.local 9000 2>&1 | grep -q "succeeded"; then
    echo "✅ MinIO (9000) acessível"
else
    echo "⚠️  MinIO pode não estar acessível"
fi

# Teste 3: Spark Shell com Iceberg
echo "[3/3] Testando Spark Shell com Iceberg..."
cat > /tmp/test_spark_iceberg.scala << 'EOF'
// Teste básico de Iceberg no Spark
println("Spark session iniciada com sucesso!")

// Verificar se Iceberg está disponível
try {
  spark.sql("SELECT * FROM iceberg.sqlite.appid_tbl LIMIT 1").show()
  println("✅ Acesso ao Iceberg OK")
} catch {
  case e: Exception => {
    println("⚠️  Acesso ao Iceberg: " + e.getMessage.substring(0, Math.min(100, e.getMessage.length)))
  }
}

// Sair
System.exit(0)
EOF

echo "Executando teste no Spark Shell..."
$SPARK_HOME/bin/spark-shell -i /tmp/test_spark_iceberg.scala 2>&1 | tail -20

echo ""
echo "=========================================="
echo "Testes Concluídos!"
echo "=========================================="
echo ""
echo "Para iniciar o Spark Master:"
echo "  /opt/spark/sbin/start-master.sh"
echo ""
echo "Para acessar a Web UI:"
echo "  http://spark.gti.local:8080"
echo ""
