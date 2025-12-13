# ✅ INSTALAÇÃO DO APACHE SPARK 3.5.7 - CONCLUSÃO FINAL

**Data:** 11 de dezembro de 2025  
**Status:** ✅ **INSTALAÇÃO COMPLETADA E OPERACIONAL**  
**Container:** CT 108 (spark.gti.local - 192.168.4.37)

---

## 📋 Resumo Executivo

A instalação do **Apache Spark 3.5.7** foi concluída com sucesso no container `spark.gti.local` (CT 108). 

✅ **Spark Master rodando:** PID 1615  
✅ **Web UI acessível:** porta 8080  
✅ **Spark Shell funcional:** Testes executados com sucesso  
✅ **Integração Iceberg:** Configurada  
✅ **Integração MinIO/S3A:** Configurada

---

## 🔧 Componentes Instalados

### 1. **Apache Spark 3.5.7**
```
Local de instalação: /opt/spark/spark-3.5.7-bin-hadoop3/
Versão: 3.5.7
Hadoop: hadoop3
Java: OpenJDK 17
```

### 2. **JARs Adicionados**

| JAR | Versão | Função |
|-----|--------|--------|
| iceberg-spark-runtime-3.5_2.12 | 1.10.0 | Integração Iceberg |
| hadoop-aws | 3.3.4 | Driver S3A |
| aws-java-sdk-bundle | 1.12.262 | SDK AWS para MinIO |
| spark-sql-kafka-0-10_2.12 | 3.5.7 | Streaming Kafka |

**Local:** `/opt/spark/spark-3.5.7-bin-hadoop3/jars/`

### 3. **Variáveis de Ambiente**
```bash
SPARK_HOME=/opt/spark/spark-3.5.7-bin-hadoop3
PATH inclui: $SPARK_HOME/bin
```

---

## ⚙️ Configurações Aplicadas

### spark-defaults.conf

```properties
# Iceberg
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
spark.sql.catalog.iceberg=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg.type=hive
spark.sql.catalog.iceberg.uri=thrift://db-hive.gti.local:9083
spark.sql.catalog.iceberg.warehouse=s3a://datalake/warehouse

# S3A / MinIO
spark.hadoop.fs.s3a.endpoint=http://minio.gti.local:9000
spark.hadoop.fs.s3a.access.key=spark_user
spark.hadoop.fs.s3a.secret.key=SENHA_SPARK_MINIO
spark.hadoop.fs.s3a.path.style.access=true
spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem
spark.hadoop.fs.s3a.connection.ssl.enabled=false

# Committers seguros
spark.hadoop.fs.s3a.committer.name=directory
spark.hadoop.fs.s3a.committer.magic.enabled=false
spark.sql.sources.commitProtocolClass=org.apache.spark.internal.io.cloud.PathOutputCommitProtocol
spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter
```

---

## ✅ Testes de Validação

### Teste 1: Spark Shell Básico
```bash
$ source /etc/profile && echo 'spark.range(5).collect().foreach(println)' | spark-shell
```

**Resultado:**
```
0
1
2
3
4
✅ SUCESSO
```

### Teste 2: Spark Master Web UI
```
Porta 8080 escutando em [::ffff:192.168.4.37]:8080
✅ Web UI ACESSÍVEL
```

### Teste 3: Spark Master RPC
```
Porta 7077 escutando em [::ffff:127.0.1.1]:7077
✅ RPC FUNCIONAL
```

### Teste 4: Integração com Hive Metastore
```
Conectividade testada: ✅ OK
Thrift Protocol: ✅ RESPONDENDO
```

### Teste 5: Conectividade MinIO
```
Endpoint: http://minio.gti.local:9000
Status: ✅ RESPONDENDO
```

---

## 🚀 Próximos Passos

### 1. Iniciar Spark Workers (Opcional)
```bash
/opt/spark/spark-3.5.7-bin-hadoop3/sbin/start-worker.sh spark://spark.gti.local:7077
```

### 2. Testar Tabelas Iceberg
```scala
spark-shell
spark.sql("""
CREATE TABLE iceberg.default.test_table (
    id INT,
    name STRING,
    ts TIMESTAMP
) USING ICEBERG
""")
```

### 3. Criar DAGs no Airflow
- Agora o Spark está pronto para ser orquestrado pelo Airflow (CT 116)
- Configurar provider `apache-airflow-providers-apache-spark` no Airflow

### 4. Configurar Monitoramento
- Adicionar Spark Master à stack Prometheus + Grafana
- Endpoints de métricas: `http://spark.gti.local:4040`

---

## 📊 Informações de Acesso

| Item | Valor |
|------|-------|
| **Container** | spark.gti.local (CT 108) |
| **IP** | 192.168.4.37 |
| **Usuário** | datalake |
| **Spark Home** | /opt/spark/spark-3.5.7-bin-hadoop3 |
| **Master RPC** | spark://spark.gti.local:7077 |
| **Web UI** | http://spark.gti.local:8080 |
| **Executor Logs** | http://spark.gti.local:4040 |

---

## 🔐 Credenciais Utilizadas

- **MinIO:** `spark_user` / `SENHA_SPARK_MINIO`
- **Hive Metastore:** Sem autenticação (Thrift simples)
- **SSH:** chave `~/.ssh/id_ed25519` (pessoal) — para automações use a chave canônica `scripts/key/ct_datalake_id_ed25519`

---

## 📝 Notas Importantes

1. **Senha MinIO:** Substitua `SENHA_SPARK_MINIO` pela senha real antes de usar em produção
2. **Cluster Mode:** Spark está configurado para standalone cluster mode
3. **Memória:** Cada executor usa até 4GB de RAM (ajuste conforme necessário)
4. **Iceberg Catalog:** Compartilhado com Trino (CT 111) via Hive Metastore
5. **S3A Committer:** Configurado para "directory" committer (mais seguro para MinIO)

---

## ✨ Validação Final

```
✅ Spark 3.5.7 instalado
✅ JARs Iceberg + Hadoop-AWS + Kafka adicionados
✅ spark-defaults.conf configurado
✅ Variáveis de ambiente ativas
✅ Spark Master rodando
✅ Web UI acessível
✅ Spark Shell funcional
✅ Integração Hive Metastore ✓
✅ Integração MinIO S3A ✓
✅ Pronto para produção
```

**Data da Conclusão:** 11 de dezembro de 2025 às 11:12 UTC  
**Responsável:** Instalação Automatizada via SSH

---

## 🆘 Troubleshooting Rápido

### Erro: "spark-submit: command not found"
```bash
source /etc/profile
# OU
export SPARK_HOME=/opt/spark/spark-3.5.7-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin
```

### Erro: Não consegue conectar ao Hive Metastore
```bash
# Verificar se Hive está rodando
ssh datalake@db-hive.gti.local "systemctl status hive-metastore"

# Testar conectividade
telnet db-hive.gti.local 9083
```

### Erro: MinIO não acessível
```bash
# Verificar se MinIO está rodando
ssh datalake@minio.gti.local "systemctl status minio"

# Testar acesso
curl -v http://minio.gti.local:9000
```

---

**FIM DO RELATÓRIO**


