# Capítulo 3: Ingestão e Gerenciamento de Dados

O DataLake FB v2 utiliza o formato Apache Iceberg para gerenciar tabelas de dados de forma transacional e eficiente. Este capítulo aborda como ingerir dados e gerenciar o ciclo de vida das tabelas.

## 1. Scripts de Ingestão (`src/`)

O repositório fornece scripts Python prontos para facilitar a ingestão de dados brutos para o Data Lake.

### Criando Tabelas (`create_iceberg_table.py`)

Antes de ingerir dados, é recomendável definir a estrutura da tabela, embora o Iceberg suporte a criação automática na escrita.

**Uso:**
```bash
python3 src/create_iceberg_table.py
```

Este script conecta-se ao Spark e cria a tabela `iceberg.default.customer_events_raw` com um esquema pré-definido e particionamento por data.

### Ingestão de Dados (`ingest_iceberg.py`)

Este script lê arquivos JSON brutos de um bucket "landing" no MinIO e os escreve na tabela Iceberg gerenciada.

**Uso:**
```bash
python3 src/ingest_iceberg.py
```

**O que ele faz:**
1.  Lê arquivos `.json` recursivamente do caminho `s3a://datalake/topics/datagen.customer.events/`.
2.  Utiliza o Spark para processar os dados em paralelo.
3.  Escreve os dados na tabela `iceberg.default.customer_events_raw` usando a operação `append` (anexar) ou `createOrReplace` se for a primeira carga.

## 2. Gerenciamento de Tabelas Iceberg

### Estrutura de Tabela
As tabelas Iceberg não são apenas arquivos soltos; elas possuem uma camada de metadados robusta.

- **Arquivos de Dados:** Parquet (armazenam os dados reais).
- **Arquivos de Manifesto:** Listam os arquivos de dados que compõem um snapshot.
- **Arquivos de Snapshot:** Representam o estado da tabela em um momento específico.

### Evolução de Schema
O Iceberg permite alterar o esquema da tabela sem reescrever os dados. Você pode adicionar colunas, renomeá-las ou alterar tipos de forma segura.

Exemplo SQL via Trino ou Spark:
```sql
ALTER TABLE iceberg.default.customer_events_raw ADD COLUMN nova_coluna string;
```

### Particionamento Oculto
O script de criação define:
```python
PARTITIONED BY (truncate(4, event_ts))
```
Isso significa que os dados são fisicamente organizados por ano (os primeiros 4 caracteres do timestamp), mas você pode consultar usando o timestamp completo e o Iceberg fará o "pruning" das partições automaticamente.

## 3. Time Travel (Viagem no Tempo)

Uma das funcionalidades mais poderosas é a capacidade de consultar dados como eles eram no passado.

**Exemplo via Spark:**
```python
# Ler versão específica por ID do Snapshot
spark.read \
    .option("snapshot-id", 123456789) \
    .table("iceberg.default.customer_events_raw")

# Ler versão por Timestamp
spark.read \
    .option("as-of-timestamp", 1640995200000) \
    .table("iceberg.default.customer_events_raw")
```

Isso é útil para auditoria, correção de erros e reprodução de cenários de machine learning.

[Próximo: Análise e Visualização](./04_analise_visualizacao.md)
