# Próximas Iterações - DataLake Spark/Iceberg

**Última atualização**: 06 de Dezembro de 2025  
**Status**: ✅ DataLake Funcional com Particionamento

---

## Iteração 1: Testes de Carga e Performance (Semana 1-2)

### Objetivos
- Validar performance com datasets maiores
- Identificar gargalos
- Otimizar configurações de Spark

### Tarefas

#### 1.1 - Gerador de Dados de Teste
Criar script que gera dataset de teste com 1GB+ de dados:
- Múltiplas partições (ano/mes/dia)
- Tipos de dados variados
- Distribuição realista

```python
# test_data_generator.py
from pyspark.sql import SparkSession
from pyspark.sql.functions import rand, expr, col
import random
from datetime import datetime, timedelta

spark = SparkSession.builder \
    .appName("DataGenerator") \
    .config("spark.sql.catalog.hadoop_prod", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.hadoop_prod.type", "hadoop") \
    .config("spark.sql.catalog.hadoop_prod.warehouse", "s3a://datalake/warehouse") \
    .getOrCreate()

# Gerar dados de vendas
n_records = 1_000_000
dates = [datetime(2023, 1, 1) + timedelta(days=x) for x in range(365)]

data = spark.range(n_records) \
    .select(
        (col("id") + 1).alias("id"),
        expr("concat('PROD_', cast(rand() * 1000 as int))").alias("produto"),
        expr("rand() * 1000").alias("valor"),
        expr("rand() * 100").alias("quantidade")
    )
```

**Entregáveis:**
- [ ] Script com gerador de dados parametrizável
- [ ] Dataset de teste de 1GB em S3
- [ ] Documentação de schema

#### 1.2 - Benchmark de Queries
Executar suite de queries e registrar performance:

```python
# queries de teste
queries = {
    "full_scan": "SELECT COUNT(*) FROM vendas",
    "partition_filter": "SELECT COUNT(*) FROM vendas WHERE ano = 2023 AND mes = 1",
    "aggregation": "SELECT produto, SUM(valor) FROM vendas GROUP BY produto",
    "join": "SELECT * FROM vendas v1 JOIN estoque e ON v1.produto = e.produto"
}
```

**Métricas a coletar:**
- Tempo de execução
- Dados processados (GB)
- Shuffle bytes
- Executors utilizados

**Entregáveis:**
- [ ] Script de benchmark parametrizável
- [ ] Relatório de performance
- [ ] Gráficos de comparação

#### 1.3 - Otimização de Configurações
Testar variações de configs Spark:
- Memory per executor: 512MB, 1GB, 2GB, 4GB
- Número de cores: 1, 2, 4, 8
- Parallelism: default vs 2x vs 4x

**Entregáveis:**
- [ ] Matriz de testes de configurações
- [ ] Recomendações de setup
- [ ] spark-defaults-optimized.conf

---

## Iteração 2: Features Avançadas de Iceberg (Semana 3-4)

### Objetivos
- Implementar Time Travel
- Testar Upsert (MERGE INTO)
- Schema Evolution

### Tarefas

#### 2.1 - Time Travel
Implementar consultas de versões históricas:

```python
# test_time_travel.py

# Versão atual
spark.sql("SELECT * FROM vendas").show()

# Versão anterior
spark.sql("SELECT * FROM vendas VERSION AS OF 1").show()

# Dados deletados há 2 horas
spark.sql("""
SELECT * FROM vendas TIMESTAMP AS OF '2025-12-06 22:00:00'
""").show()
```

**Entregáveis:**
- [ ] Script de time travel exemplificando
- [ ] Documentação de syntax
- [ ] Casos de uso e limitações

#### 2.2 - Upsert (MERGE INTO)
Implementar operações de upsert:

```python
# test_upsert.py

spark.sql("""
MERGE INTO vendas t
USING (SELECT * FROM vendas_staging) s
ON t.id = s.id
WHEN MATCHED THEN UPDATE SET valor = s.valor
WHEN NOT MATCHED THEN INSERT *
""")
```

**Entregáveis:**
- [ ] Script com exemplos de MERGE
- [ ] Testes de performance de upsert
- [ ] Comparação INSERT vs MERGE

#### 2.3 - Schema Evolution
Testar alteração de schema:

```python
# test_schema_evolution.py

# Add column
spark.sql("ALTER TABLE vendas ADD COLUMN desconto DOUBLE DEFAULT 0.0")

# Rename column
spark.sql("ALTER TABLE vendas RENAME COLUMN quantidade TO qtd")

# Change column type
spark.sql("ALTER TABLE vendas ALTER COLUMN valor TYPE DECIMAL(10,2)")
```

**Entregáveis:**
- [ ] Script com exemplo de evolução
- [ ] Teste de compatibilidade backward
- [ ] Documentação de limitações

#### 2.4 - Compaction e Otimização
Implementar rotina de maintenance:

```python
# test_maintenance.py

# Rewrite data files (compaction)
spark.sql("""
CALL hadoop_prod.system.rewrite_data_files(
    table => 'vendas',
    strategy => 'binpack',
    sort_order => 'valor DESC'
)
""")

# Rewrite manifests
spark.sql("""
CALL hadoop_prod.system.rewrite_manifests(table => 'vendas')
""")

# Remove orphan files
spark.sql("""
CALL hadoop_prod.system.remove_orphan_files(table => 'vendas')
""")
```

**Entregáveis:**
- [ ] Script de maintenance
- [ ] Agendador de tarefas (cron/airflow)
- [ ] Métricas antes/depois

---

## Iteração 3: Monitoramento e Observabilidade (Semana 5-6)

### Objetivos
- Implementar métricas e alertas
- Visualizar performance em tempo real
- Rastrear queries lentas

### Tarefas

#### 3.1 - Coleta de Métricas
Implementar exportação de métricas:

```python
# metrics_collector.py

import json
from datetime import datetime

metrics = {
    "timestamp": datetime.now().isoformat(),
    "table": "vendas",
    "total_rows": 1000000,
    "data_size_mb": 500,
    "file_count": 128,
    "average_file_size_mb": 4,
    "partition_count": 12,
    "snapshots_count": 45
}

# Salvar em S3 para análise
# Ou enviar para sistema de monitoramento
```

**Entregáveis:**
- [ ] Script de coleta de métricas
- [ ] Formato de saída (JSON/CSV)
- [ ] Integração com Prometheus ou similar

#### 3.2 - Alertas e SLAs
Definir alertas para:
- Query execution time > 5 minutos
- Table size crescimento > 100GB/mês
- Query failures (>1 por hora)
- Snapshot age > 30 dias (sem limpeza)

**Entregáveis:**
- [ ] Script de verificação de SLAs
- [ ] Configuração de alertas
- [ ] Integração com Slack/Email

#### 3.3 - Dashboard Grafana
Criar visualizações:
- Evolução de tamanho de tabelas
- Latência de queries por tipo
- Distribuição de dados por partição
- Taxa de escritas vs leituras

**Entregáveis:**
- [ ] Painéis Grafana
- [ ] Datasource Prometheus ou equivalente
- [ ] Documentação de uso

#### 3.4 - Query Performance Analysis
Implementar análise de queries lentas:

```python
# slow_query_analyzer.py

# Capturar event logs de Spark
# Identificar:
# - Shuffle stages
# - Data skewness
# - Missing indexes/statistics
```

**Entregáveis:**
- [ ] Script de análise
- [ ] Relatório de queries lentas
- [ ] Recomendações de otimização

---

## Iteração 4: Backup e Disaster Recovery (Semana 7-8)

### Objetivos
- Implementar estratégia de backup
- Testar recuperação
- Documentar procedimentos

### Tarefas

#### 4.1 - Backup Automático
Implementar rotina de backup:

```bash
# backup_daily.sh

# Snapshot de todas as tabelas
# Copiar metadados para S3 secondary
# Registrar versão de backup
```

**Entregáveis:**
- [ ] Script de backup diário
- [ ] Rotação de backups (7 dias)
- [ ] Verificação de integridade

#### 4.2 - Teste de Recuperação
Documentar e testar:
- Recuperação de tabela única
- Recuperação de warehouse inteiro
- Recuperação até ponto específico no tempo

**Entregáveis:**
- [ ] Procedimento documentado
- [ ] Teste bem-sucedido de recuperação
- [ ] Tempo de RTO/RPO registrado

#### 4.3 - Cross-Region Replication
(Opcional para produção)

```bash
# replicate_to_secondary.sh

# Sincronizar warehouse S3 primary → secondary
# Manter sincronização incremental
```

**Entregáveis:**
- [ ] Script de replicação
- [ ] Teste de failover
- [ ] Documentação

---

## Iteração 5: Produção e Hardening (Semana 9-10)

### Objetivos
- Preparar para ambiente de produção
- Implementar segurança
- Documentar arquitetura

### Tarefas

#### 5.1 - Segurança
- Habilitar SSL/TLS para MinIO
- Implementar IAM policies
- Auditing e logging
- Criptografia em repouso

#### 5.2 - High Availability
- Multiple Spark workers
- Load balancing
- Failover automático

#### 5.3 - Documentação
- Architecture Diagrams
- Runbooks de operação
- Troubleshooting guide
- SLOs/SLIs definidos

#### 5.4 - Handover
- Treinamento de equipe ops
- Playbooks de resposta a incidentes
- Escalation procedures

---

## Checklist de Conclusão

### Iteração 1 ✅/⏳
- [ ] Gerador de dados criado
- [ ] Benchmarks executados
- [ ] Otimizações implementadas

### Iteração 2 ⏳
- [ ] Time Travel testado
- [ ] Upsert funcionando
- [ ] Schema Evolution testado
- [ ] Maintenance automatizada

### Iteração 3 ⏳
- [ ] Métricas coletadas
- [ ] Alertas configurados
- [ ] Dashboard Grafana online
- [ ] Query analysis em produção

### Iteração 4 ⏳
- [ ] Backup automático rodando
- [ ] Recuperação testada
- [ ] RTO/RPO documentado

### Iteração 5 ⏳
- [ ] Ambiente de produção pronto
- [ ] Documentação completa
- [ ] Equipe treinada

---

## Métricas de Sucesso

| Métrica | Meta |
|---------|------|
| Query latency P99 | < 30s |
| Data ingestion rate | > 10GB/hora |
| Availability | > 99.5% |
| RTO (Recovery Time Objective) | < 4 horas |
| RPO (Recovery Point Objective) | < 1 hora |
| Backup success rate | 100% |
| Documentation coverage | > 90% |

---

## Contatos e Escalação

| Papel | Contato | Telefone |
|------|---------|----------|
| Data Engineer Lead | - | - |
| Infra/Ops Lead | - | - |
| DBA | - | - |

---

**Próxima reunião**: [DATA]  
**Anotações da última reunião**: [LINK]
