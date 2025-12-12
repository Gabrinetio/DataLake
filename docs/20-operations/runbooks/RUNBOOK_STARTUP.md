# 🚀 RUNBOOK_STARTUP.md - Iniciar Cluster DataLake

**Data de Criação:** 9 de dezembro de 2025
**Versão:** 1.0
**Responsável:** DataLake Operations Team

---

## 📋 Visão Geral

Este runbook descreve o procedimento padrão para iniciar o cluster DataLake Iceberg em produção.

**Tempo Estimado:** 15-20 minutos
**Pré-requisitos:** Acesso root ao servidor 192.168.4.33

---

## 🔍 Pré-verificações

### Sistema
- [ ] **Espaço em disco:** Verificar >50GB disponível
  ```bash
  df -h / | grep -v tmpfs
  ```
- [ ] **Memória:** Verificar >8GB RAM disponível
  ```bash
  free -h
  ```
- [ ] **CPU:** Verificar carga < 2.0
  ```bash
  uptime
  ```

### Rede
- [ ] **Conectividade:** Testar acesso ao servidor
  ```bash
  ping -c 3 192.168.4.33
  ```
- [ ] **Portas abertas:** Verificar portas críticas
  ```bash
  netstat -tlnp | grep -E ':(3306|9000|9092|8080|10000)'
  ```

### Segurança
- [ ] **SSH:** Acesso root funcionando
  ```bash
  ssh root@192.168.4.33 "echo 'SSH OK'"
  ```
- [ ] **Firewall:** Regras ativas
  ```bash
  ufw status
  ```

---

## 🚀 Sequência de Startup

### 1. MariaDB (Banco de Metadados)
```bash
# Iniciar serviço
systemctl start mariadb

# Verificar status
systemctl status mariadb --no-pager -l

# Testar conectividade
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT VERSION();"
```

### 2. Hive Metastore
```bash
# Iniciar serviço
systemctl start hive-metastore

# Verificar logs
tail -f /opt/hive/logs/hive-metastore.log

# Testar conectividade
beeline -u "jdbc:hive2://localhost:10000" -n hive -e "SHOW DATABASES;"
```

### 3. MinIO (Storage S3)
```bash
# Iniciar serviço
systemctl start minio

# Verificar status
systemctl status minio --no-pager

# Testar API
curl -I http://localhost:9000/minio/health/live
```

### 4. Kafka (Streaming)
```bash
# Iniciar Zookeeper primeiro
systemctl start zookeeper

# Iniciar Kafka
systemctl start kafka

# Verificar tópicos
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

### 5. Spark Master
```bash
# Iniciar Spark Master
/opt/spark/sbin/start-master.sh

# Verificar web UI
curl -s http://localhost:8080 | grep -q "Spark Master" && echo "Spark Master OK"
```

---

## ✅ Validações Pós-Startup

### Teste Básico de Funcionalidade
```bash
# Arquivo: test_startup_validation.py
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("StartupValidation") \
    .master("spark://localhost:7077") \
    .getOrCreate()

# Teste 1: Conexão Spark
print("✅ Spark conectado")

# Teste 2: Acesso MinIO S3
spark.sparkContext.hadoopConfiguration.set("fs.s3a.access.key", "datalake")
spark.sparkContext.hadoopConfiguration.set("fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!")
spark.sparkContext.hadoopConfiguration.set("fs.s3a.endpoint", "http://localhost:9000")
spark.sparkContext.hadoopConfiguration.set("fs.s3a.path.style.access", "true")

# Criar DataFrame de teste
df = spark.range(100).selectExpr("id", "id * 2 as doubled")
df.write.mode("overwrite").parquet("s3a://datalake/test_startup")

print("✅ MinIO S3 acessível")

# Teste 3: Hive/Iceberg
spark.sql("CREATE DATABASE IF NOT EXISTS test")
spark.sql("USE test")
spark.sql("CREATE TABLE test_table (id INT, value STRING) USING iceberg")

print("✅ Iceberg/Hive funcionando")

spark.stop()
print("🎉 CLUSTER TOTALMENTE OPERACIONAL!")
```

### Executar validação
```bash
cd /home/datalake
python test_startup_validation.py
```

---

## 🔧 Troubleshooting

### Problema: MariaDB não inicia
```bash
# Verificar logs
journalctl -u mariadb --no-pager -n 50

# Recovery se necessário
mysql -u root -p < /tmp/recovery.sql

# Reset root password se necessário
mysqld_safe --skip-grant-tables &
mysql -u root -e "UPDATE mysql.user SET password=PASSWORD('NEW_PASSWORD') WHERE user='root'; FLUSH PRIVILEGES;"
```

### Problema: Hive Metastore falha
```bash
# Verificar conectividade MariaDB
mysql -u hive -p"$HIVE_METASTORE_PASSWORD" -e "USE metastore; SHOW TABLES;"

# Logs detalhados
tail -f /opt/hive/logs/hive-metastore.log

# Reinicializar metastore
schematool -dbType mysql -initSchema
```

### Problema: MinIO não responde
```bash
# Verificar processo
ps aux | grep minio

# Logs
journalctl -u minio --no-pager -n 20

# Teste direto
mc alias set local http://localhost:9000 datalake iRB;g2&ChZ&XQEW!
mc ls local/
```

### Problema: Kafka não conecta
```bash
# Verificar Zookeeper
echo "ruok" | nc localhost 2181

# Logs Kafka
tail -f /opt/kafka/logs/server.log

# Reset se necessário
rm -rf /tmp/kafka-logs/
```

### Problema: Spark Master falha
```bash
# Logs Spark
tail -f /opt/spark/logs/spark-root-org.apache.spark.deploy.master.Master*.out

# Verificar JAVA_HOME
echo $JAVA_HOME

# Verificar portas
netstat -tlnp | grep 7077
```

---

## 📞 Contatos de Emergência

- **Lead DBA:** [Nome] - [Telefone] - [Email]
- **Lead DevOps:** [Nome] - [Telefone] - [Email]
- **On-Call Engineer:** [Nome] - [Telefone] - [Email]

**Escalation:** Se problema não resolvido em 30 min, escalar para gerente técnico.

---

## 📝 Registro de Execuções

| Data/Hora | Executor | Status | Observações |
|-----------|----------|--------|-------------|
| 2025-12-09 15:30 | [Nome] | ✅ Sucesso | Startup completo em 12 min |
| | | | |
| | | | |
| | | | |

---

*Última atualização: 9 de dezembro de 2025*</content>
<parameter name="filePath">c:\Users\Gabriel Santana\Documents\VS_Code\DataLake_FB-v2\etc\runbooks\RUNBOOK_STARTUP.md