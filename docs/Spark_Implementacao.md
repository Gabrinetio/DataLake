# Implementação do Apache Spark

Este documento descreve os passos de instalação e configuração do Apache Spark (standalone) integrando com Hive Metastore e MinIO (S3).

Pré-requisitos:
- MinIO configurado (`minio.gti.local:9000`) e buckets criados.
- Hive Metastore rodando em `thrift://db-hive.gti.local:9083`.
- HADOOP_HOME e JAVA_HOME configurados no servidor.

Instalação automatizada:

1. Instalar o Spark e jars necessários

```bash
sudo bash etc/scripts/install-spark.sh
```

2. Configurar o Spark com credenciais do MinIO e o metastore do Hive

Edite `/etc/spark/spark.env` ou `etc/scripts/spark.env` (ou `.env` local) adicionando as variáveis:

```ini
SPARK_HOME=/opt/spark
SPARK_MINIO_ENDPOINT=http://minio.gti.local:9000
SPARK_MINIO_USER=spark_user
SPARK_MINIO_PASS=SparkPass123!
HIVE_METASTORE_URI=thrift://db-hive.gti.local:9083
ICEBERG_WAREHOUSE=s3a://datalake/warehouse
```

Executar a configuração:

```bash
sudo bash etc/scripts/configure-spark.sh
```

3. Registrar unidades systemd e iniciar os serviços

Copie os templates de systemd para `/etc/systemd/system/` e habilite:

```bash
sudo cp etc/systemd/spark-master.service.template /etc/systemd/system/spark-master.service
sudo cp etc/systemd/spark-worker.service.template /etc/systemd/system/spark-worker.service
sudo systemctl daemon-reload
sudo systemctl enable --now spark-master
sudo systemctl enable --now spark-worker
```

4. Teste do Spark + Iceberg

Abra o `spark-shell` e crie/consulte uma tabela Iceberg apontando para o `catalog.iceberg` configurado no `spark-defaults.conf`.

```scala
// Exemplo: criar tabela e inserir
spark.sql("CREATE TABLE iceberg.default.tbl (id long, value string) USING iceberg")
spark.sql("INSERT INTO iceberg.default.tbl VALUES (1, 'valor')")
spark.sql("SELECT * FROM iceberg.default.tbl").show()
```

Observações:
- Ajuste as versões de `hadoop-aws`, `aws-java-sdk-bundle` e `iceberg-spark-runtime` conforme compatibilidade do Hadoop/Spark.
- Por segurança, prefira armazenar credenciais em `/etc/spark/spark.env` e proteger este arquivo com `chmod 600`.

## Ajustes Pós-Instalação

### Configuração de Rede para Spark

Para evitar warnings sobre hostname resolvendo para loopback, configure o IP local no `spark-env.sh`:

```bash
sudo cp /opt/spark/conf/spark-env.sh.template /opt/spark/conf/spark-env.sh
echo 'SPARK_LOCAL_IP=192.168.4.33' | sudo tee -a /opt/spark/conf/spark-env.sh
```

Substitua `192.168.4.33` pelo IP real do servidor Spark. Verifique com `hostname -I`.

### Configuração de Credenciais MinIO e Hive

Configure o `spark-defaults.conf` com credenciais para acesso ao MinIO (S3) e Hive Metastore:

```bash
sudo cp /opt/spark/conf/spark-defaults.conf.template /opt/spark/conf/spark-defaults.conf
```

Adicione as seguintes linhas ao `spark-defaults.conf`:

```
# Configurações MinIO S3
spark.hadoop.fs.s3a.endpoint http://minio.gti.local:9000
spark.hadoop.fs.s3a.access.key spark_user
spark.hadoop.fs.s3a.secret.key iRB;g2&ChZ&XQEW!
spark.hadoop.fs.s3a.path.style.access true
spark.hadoop.fs.s3a.connection.ssl.enabled false

# Configurações Hive/Iceberg
spark.sql.catalog.iceberg.uri thrift://db-hive.gti.local:9083
spark.sql.catalog.iceberg.type hive
spark.sql.catalog.iceberg.warehouse s3a://datalake/warehouse
```

**Nota**: Substitua as credenciais pelos valores reais do ambiente. Mantenha o arquivo protegido com permissões adequadas.

## Status dos Testes

### Teste de Integração Spark + S3 + Iceberg

**Data do último teste**: 06/12/2025

**Resultado**:
- ✅ **Hive Metastore**: Funcionando corretamente. Spark consegue conectar ao metastore e executar queries SQL (SHOW DATABASES).
- ✅ **S3A (MinIO)**: Resolvido! Spark agora consegue acessar o MinIO S3. O problema era que as configurações no `spark-defaults.conf` não carregavam os jars corretamente. A solução foi definir as configurações S3A diretamente na SparkSession no código Python.
- ✅ **Iceberg Tables**: SUCESSO! Tabelas Iceberg foram criadas, dados inseridos e consultados com sucesso no S3. O problema inicial com locks do Hive Metastore foi resolvido usando catálogo Hadoop em vez de Hive.

**Configurações atuais**:
- Spark 3.5.7 com Hadoop 3.3.4 embutido
- Hadoop 3.3.6 instalado separadamente em /opt/hadoop
- HADOOP_HOME=/opt/hadoop
- SPARK_DIST_CLASSPATH=/opt/hadoop/etc/hadoop
- core-site.xml configurado com credenciais S3A
- Catálogo Iceberg configurado como Hadoop (type: hadoop) para evitar problemas de locks
- Warehouse: s3a://datalake/warehouse

**Solução para Iceberg**:
O problema com locks do Hive Metastore foi resolvido configurando o catálogo Spark como Hadoop em vez de Hive:

```python
spark = SparkSession.builder \
    .appName('TestIcebergTable') \
    .config('spark.hadoop.fs.s3a.endpoint', 'http://minio.gti.local:9000') \
    .config('spark.hadoop.fs.s3a.access.key', 'spark_user') \
    .config('spark.hadoop.fs.s3a.secret.key', 'SparkPass123!') \
    .config('spark.hadoop.fs.s3a.path.style.access', 'true') \
    .config('spark.hadoop.fs.s3a.connection.ssl.enabled', 'false') \
    .config('spark.hadoop.fs.s3a.impl', 'org.apache.hadoop.fs.s3a.S3AFileSystem') \
    .config('spark.sql.catalog.spark_catalog', 'org.apache.iceberg.spark.SparkSessionCatalog') \
    .config('spark.sql.catalog.spark_catalog.type', 'hadoop') \
    .config('spark.sql.catalog.spark_catalog.warehouse', 's3a://datalake/warehouse') \
    .getOrCreate()
```

**Arquivos criados no MinIO**:
- Metadados: `s3a://datalake/warehouse/default/test_iceberg/metadata/`
- Dados: `s3a://datalake/warehouse/default/test_iceberg/data/` (arquivos Parquet)

**Teste bem-sucedido**:
```sql
-- Criação da tabela
CREATE TABLE spark_catalog.default.test_iceberg (
    id INT,
    nome STRING,
    valor DOUBLE,
    data_criacao TIMESTAMP
) USING iceberg
LOCATION 's3a://datalake/warehouse/default/test_iceberg'

-- Inserção de dados
INSERT INTO spark_catalog.default.test_iceberg VALUES
(1, 'Produto A', 100.50, current_timestamp()),
(2, 'Produto B', 250.75, current_timestamp()),
(3, 'Produto C', 75.25, current_timestamp())

-- Consulta
SELECT * FROM spark_catalog.default.test_iceberg
```

**Resultado do teste**:
```
+---+---------+------+--------------------+
| id|     nome| valor|        data_criacao|
+---+---------+------+--------------------+
|  1|Produto A| 100.5|2025-12-06 13:07:...|
|  2|Produto B|250.75|2025-12-06 13:07:...|
|  3|Produto C| 75.25|2025-12-06 13:07:...|
+---+---------+------+--------------------+
```

**Status**: ✅ **DataLake funcional!** Spark + MinIO S3 + Iceberg funcionando perfeitamente.

---

## Implementação de Tabelas Particionadas Iceberg (Dec 2025)

Após validar a funcionalidade básica de Iceberg, implementamos suporte a tabelas particionadas para melhorar performance de queries.

### Script de Teste: `test_iceberg_partitioned.py`

Demonstra criação e manipulação de tabelas particionadas:

```python
# Criar tabela com particionamento
spark.sql("""
CREATE TABLE IF NOT EXISTS hadoop_prod.default.vendas_partitioned (
    id INT,
    produto STRING,
    valor DOUBLE,
    data_venda DATE
)
USING iceberg
PARTITIONED BY (ano INT, mes INT)
""")

# Inserir dados com valores de partição
spark.sql("""
INSERT INTO hadoop_prod.default.vendas_partitioned (id, produto, valor, data_venda, ano, mes)
VALUES
(1, 'Produto A', 100.0, CAST('2023-01-15' AS DATE), 2023, 1),
(2, 'Produto B', 200.0, CAST('2023-02-20' AS DATE), 2023, 2)
""")

# Consultar com partition pruning
spark.sql("""
SELECT * FROM hadoop_prod.default.vendas_partitioned 
WHERE ano = 2023 AND mes = 1
""").show()
```

### Resultados Obtidos

✅ **Tabelas particionadas funcionando com sucesso:**
- Criação de tabelas com `PARTITIONED BY` clause
- Inserção de dados com colunas de partição
- Queries com partition pruning (filtro por ano/mes)
- Dados persistidos corretamente em MinIO S3

### Próximos Passos Recomendados

#### 1. Otimização de Tabelas
```bash
# Executar Rewrite e Cleanup via Spark SQL
spark.sql("CALL hadoop_prod.system.rewrite_manifests(table => 'table_name')")
spark.sql("CALL hadoop_prod.system.remove_orphan_files(table => 'table_name')")
```

#### 2. Monitoramento e Performance
- Acompanhar métricas de execução
- Implementar alertas para crescimento do warehouse
- Coletar estatísticas de queries

#### 3. Testes de Carga
- Inserir datasets maiores (GB/TB)
- Validar performance com múltiplos workers
- Testar queries agregadas complexas

#### 4. Backup e Disaster Recovery
- Configurar snapshots automáticos
- Implementar replicação
- Documentar procedimentos de recuperação

### Configuração Atual

**Catálogo Iceberg (Hadoop):**
```
Type: hadoop
Warehouse: s3a://datalake/warehouse
Endpoint: http://localhost:9000
User: spark_user / SparkPass123!
```

**Status Final**: ✅ **DataLake com Particionamento em Produção!**





