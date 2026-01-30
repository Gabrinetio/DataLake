# 📘 **Arquitetura da Plataforma de Dados GTI (Docker Edition)**

### **Versão 2.0 – Stack Unificada em Docker**

---

# 📑 **ÍNDICE**

1.  [Visão Geral](#1-visão-geral-do-projeto)
2.  [Arquitetura Técnica](#2-arquitetura-técnica)
3.  [Componentes do Ecossistema](#3-componentes-do-ecossistema)
4.  [Fluxos de Dados e Mudança](#4-fluxos)
5.  [Especificações e Versões](#5-especificações-técnicas)

---

## **1. Visão Geral do Projeto**

### **1.1 Objetivo**
Fornecer uma plataforma de dados moderna, autônoma e resiliente, baseada no conceito de **Lakehouse**. A infraestrutura é agnóstica a provedor de nuvem, rodando 100% on-premise (ou em qualquer VM Linux) através de contêineres Docker orquestrados via Docker Compose.

### **1.2 Paradigma Lakehouse**
A plataforma combina a flexibilidade de um Data Lake com a gestão de dados de um Data Warehouse:
*   **Armazenamento Barato:** Object Storage (MinIO)
*   **Transacionalidade:** Apache Iceberg (ACID, Time Travel)
*   **Processamento Escável:** Apache Spark
*   **Consulta SQL Rápida:** Trino

---

## **2. Arquitetura Técnica**

A arquitetura migrou de múltiplos containers LXC isolados para um **Stack Docker Unificado**.

### **2.1 Topologia Lógica (Docker Network)**
Todos os serviços comunicam-se através de uma rede bridge interna (`docker_datalake-net`), utilizando resolução de nomes de serviço (DNS do Docker).

```mermaid
graph TD
    subgraph "Docker Host"
        subgraph "Network: datalake-net"
            K[Kafka Cluster] --> S[Spark Cluster]
            S --> M[MinIO (S3)]
            H[Hive Metastore] -.-> M
            S -.-> H
            T[Trino] --> M
            T --> H
            B[Superset] --> T
            G[Gitea]
        end
        Ext[Datagen] -.-> K
    end
```

### **2.2 Armazenamento Persistente**
Volumes Docker nomeados garantem a persistência dos dados críticos:
*   `minio_data`: Dados brutos e tabelas Iceberg.
*   `mariadb_data`: Metadados do Hive.
*   `postgres_data`: Metadados do Superset.
*   `gitea_data` / `gitea_db`: Repositórios Git.
*   `kafka_data` / `zookeeper_data`: Logs de eventos.

---

## **3. Componentes do Ecossistema**

### **Infraestrutura Core**
1.  **MinIO (S3)**: O "disco rígido" do Lakehouse. Armazena parquets, metadados Iceberg e checkpoints.
2.  **Hive Metastore**: O catálogo central. Mapeia onde estão as tabelas Iceberg para que Spark e Trino possam encontrá-las. Backend: MariaDB.
3.  **Apache Spark (Master/Worker)**: O "motor" de processamento. Realiza ingestão (Streaming) e transformação (Batch) pesada.
4.  **Trino**: O motor de consulta SQL. Permite que analistas consultem o Lakehouse via SQL padrão com alta performance.
5.  **Kafka Stack**:
    *   **Zookeeper & Broker**: Barramento de eventos em tempo real.
    *   **Kafka Connect**: Ingestão de fontes externas (bancos, arquivos) para tópicos.
    *   **Kafka UI**: Interface de gestão.

### **Aplicações e Ferramentas**
6.  **Apache Superset**: Visualização de dados (Dashboards) conectado ao Trino.
7.  **Gitea**: Servidor Git self-hosted para versionamento de código, DAGs e configurações (GitOps).

---

## **4. Fluxos**

### **4.1 Fluxo de Dados (Pipeline Padrão)**
1.  **Ingestão**: Dados são gerados (ex: Datagen) e enviados para o **Kafka**.
2.  **Processamento**: Jobs **Spark Streaming** leem do Kafka, aplicam regras de negócio e escrevem no **MinIO** em formato **Iceberg**.
3.  **Catálogo**: O **Hive Metastore** registra os novos snapshots das tabelas.
4.  **Consumo**: Usuários usam o **Superset**, que envia SQL para o **Trino**, que lê os dados do **MinIO**.

### **4.2 Fluxo de GitOps**
1.  Desenvolvedor commita código (Job Spark ou SQL) no **Gitea**.
2.  Pipeline (ou Deployer manual) atualiza o ambiente produtivo.
3.  O código versionado é a única fonte da verdade.

---

## **5. Especificações Técnicas**

### **5.1 Versões (Stack Lock)**
| Componente | Versão | Função |
| :--- | :--- | :--- |
| **Spark** | 3.5.4 | Processamento |
| **Iceberg** | 1.10.0 | Configuração via JARs |
| **Trino** | Latest | Query Engine |
| **MinIO** | Latest | Object Storage |
| **Kafka** | 7.5.0 (CP) | Streaming |
| **Superset** | Latest | BI |
| **Gitea** | 1.24.2 | Versionamento |

### **5.2 Portas de Serviço (Host)**
| Serviço | Porta Interna | Porta Exposta (Host) |
| :--- | :--- | :--- |
| **Gitea** | 3000 | 3000 |
| **Superset** | 8088 | 8088 |
| **Trino** | 8080 | 8081 |
| **Spark Master** | 8080 | 8085 |
| **MinIO Console**| 9001 | 9001 |
| **MinIO API** | 9000 | 9000 |
| **Kafka UI** | 8080 | 8090 |
| **Kafka Broker** | 9092 | 29092 (Ext) |

### **5.3 Requisitos de Hardware (Mínimo Recomendado)**
Para rodar o stack completo via Docker:
*   **CPU**: 4 vCPUs ou mais.
*   **RAM**: 16 GB (Recomendado 32 GB para cargas de trabalho reais).
*   **Disco**: 50 GB+ SSD.

---

**Documentação mantida pela Equipe de Dados GTI.**
