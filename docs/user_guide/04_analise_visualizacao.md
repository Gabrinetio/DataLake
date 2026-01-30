# Capítulo 4: Análise e Visualização

Após a ingestão, os dados estão prontos para serem consumidos. O DataLake FB v2 oferece duas ferramentas principais para isso: Trino para consultas SQL ad-hoc e Apache Superset para dashboards.

## 1. Consultas SQL com Trino

O Trino é o motor de consulta. Ele permite acessar os dados do Iceberg usando SQL padrão ANSI.

### Acesso via DBeaver (Recomendado)
Você pode conectar seu cliente SQL favorito (DBeaver, DataGrip) ao Trino.

**Configurações de Conexão:**
*   **Tipo de Banco:** Trino
*   **Host:** `localhost`
*   **Porta:** `8086`
*   **Usuário:** `admin` (ou qualquer string)
*   **Senha:** (deixe em branco)
*   **Database/Catalog:** `iceberg`

### Exemplos de Consultas

**Listar Schemas:**
```sql
SHOW SCHEMAS;
```

**Consultar Dados:**
```sql
SELECT * FROM iceberg.default.customer_events_raw
WHERE event_ts >= '2023-01-01'
LIMIT 100;
```

**Consultar Metadados (Tabelas de Sistema do Iceberg):**
```sql
-- Ver histórico de snapshots
SELECT * FROM iceberg.default."customer_events_raw$snapshots";

-- Ver arquivos de manifesto
SELECT * FROM iceberg.default."customer_events_raw$manifests";
```

## 2. Apache Superset

O Superset é a interface visual para o usuário final.

### Acessando o Dashboard
1.  Acesse [http://localhost:8088](http://localhost:8088).
2.  Faça login com `admin` / `admin`.

### Conectando ao Banco de Dados
Se a conexão ainda não estiver configurada:
1.  Vá em **Settings** > **Database Connections**.
2.  Clique em **+ Database**.
3.  Escolha **Trino**.
4.  **SQLAlchemy URI:** 
    ```
    trino://admin@trino:8080/iceberg
    ```
    > **Nota:** Usamos o nome do serviço Docker `trino` e a porta interna `8080`.

### Criando um Dataset
1.  Vá em **Datasets** > **+ Dataset**.
2.  Selecione a conexão Trino, o schema `default` e a tabela `customer_events_raw`.
3.  Clique em **Add**.

### Criando Gráficos (Charts)
1.  Vá em **Charts** > **+ Chart**.
2.  Escolha o dataset criado e o tipo de visualização (ex: Big Number, Time Series Line Chart).
3.  Configure as métricas (ex: `COUNT(*)`).
4.  Clique em **Create Chart** e salve.

### Criando Dashboards
1.  Vá em **Dashboards** > **+ Dashboard**.
2.  Arraste e solte os gráficos criados para organizar sua visão.
3.  Salve e publique.

[Próximo: Operações e Manutenção](./05_operacoes.md)
