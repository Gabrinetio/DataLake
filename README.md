# Projeto: Plataforma Preditiva de Churn (Auto-hospedada)

**Versão:** 1.0 (Fase de Infraestrutura e Geração de Dados)  
**Data:** 31 de outubro de 2025  
**Stack Principal:** Proxmox, Debian 12 (LXC), Python, Git

---

## 1. Visão Geral do Projeto

Este repositório contém o código e a documentação para a construção de uma plataforma de dados ponta a ponta, totalmente auto-hospedada (*self-hosted*), com o objetivo de prever o **churn (cancelamento de clientes)** em negócios de assinatura.

O objetivo de negócio é analisar o comportamento dos clientes a partir de múltiplas fontes de dados para prever de maneira proativa o risco de cancelamento, permitindo que as equipes de retenção atuem de forma preventiva.

A plataforma é construída sobre uma stack 100% open-source, com a infraestrutura virtualizada em **Proxmox VE**, e segue os princípios de uma arquitetura de **Datalake** moderna.

---

## 2. Stack de Tecnologias

| Componente | Ferramenta Open-Source | Papel no Projeto |
| :--- | :--- | :--- |
| **Virtualização** | Proxmox VE | Camada de IaaS (Infrastructure as a Service) para criar e gerenciar nossos servidores virtuais. |
| **Sistema Operacional** | Debian 12 "Bookworm" | SO base para todos os containers (LXC), escolhido por sua estabilidade e leveza. |
| **Armazenamento** | MinIO | Nosso Datalake físico. Um armazenamento de objetos compatível com a API S3 para a `raw-zone` e `curated-zone`. |
| **Banco de Dados** | PostgreSQL | Servidor de banco de dados relacional que atuará como *backend metastore* para Airflow, Superset e MLflow. |
| **Orquestração** | Apache Airflow | Ferramenta para agendar, executar e monitorar os pipelines de dados (workflows de ETL). |
| **Transformação** | Apache Spark / dbt | (Futuro) Ferramentas para transformar os dados brutos em dados tratados e prontos para análise. |
| **MLOps** | MLflow | Plataforma para gerenciar o ciclo de vida dos modelos de Machine Learning (tracking, registro, deploy). |
| **Visualização (BI)** | Apache Superset | Ferramenta de Business Intelligence para criar dashboards e visualizar os dados e resultados. |

---

## 3. Arquitetura da Infraestrutura (Proxmox)

A base da nossa plataforma é o Proxmox, utilizando **Containers (LXC)** para máxima eficiência de recursos e isolamento de serviços.

### 3.1. Configuração de Rede

Para garantir segurança e controle, a topologia de rede no Proxmox foi desenhada da seguinte forma:

* **`vmbr0` (Rede Principal):** A bridge padrão ligada à rede local (LAN). Permite acesso à internet e é usada apenas pelo template durante sua criação/atualização.
* **`vmbr1` (Rede Privada do Datalake):** Uma bridge Linux **sem interface física associada**, criando uma rede puramente interna.
    * **CIDR:** `10.10.10.0/24`
    * **Gateway (no host Proxmox):** `10.10.10.1`
    * **Justificativa:** Esta topologia isola os serviços do Datalake, aumentando a segurança e garantindo que a comunicação entre eles (ex: Airflow consultando o PostgreSQL) seja feita de forma interna e segura.

### 3.2. Estrutura dos Containers (LXC)

Cada serviço é executado em seu próprio container Debian 12, clonado a partir de um template base para garantir consistência.

| ID | Hostname | Finalidade | IP (em `vmbr1`) | Recursos Mínimos |
| :- | :--- | :--- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `10.10.10.11/24` | 2 Cores, 4GB RAM, 40GB Disco |
| `102`| `minio` | Datalake Storage | `10.10.10.12/24` | 2 Cores, 2GB RAM, 200GB+ Disco|
| `103`| `airflow` | Orquestração | `10.10.10.13/24` | 4 Cores, 8GB RAM, 20GB Disco |
| `104`| `superset` | Business Intelligence | `10.10.10.14/24` | 2 Cores, 4GB RAM, 20GB Disco |
| `105`| `mlflow` | MLOps | `10.10.10.15/24` | 2 Cores, 2GB RAM, 20GB Disco |

#### Preparação do Template (`debian-12-template`)

O template base foi criado com a imagem oficial do Debian 12 e configurado com:
1. Sistema totalmente atualizado (`apt update && apt upgrade`).
2. Ferramentas essenciais pré-instaladas: `curl`, `wget`, `git`, `nano`, `python3-pip`, `python3-venv`.
3. Configuração de rede temporária em `vmbr0` com DHCP para permitir as atualizações. Esta configuração **deve ser alterada para um IP estático em `vmbr1`** ao clonar cada novo container.

---

## 4. Estrutura do Repositório e Ambiente de Desenvolvimento

O desenvolvimento dos scripts é feito localmente e versionado via Git.

### 4.1. Estrutura de Diretórios

```text
projeto-churn/
├── .gitignore                       # Arquivo para ignorar dados e arquivos de ambiente.
├── README.md                        # Este arquivo de documentação.
├── charts/                          # Diretório para gráficos e visualizações gerados pela análise.
├── data/
│   ├── raw/                         # -> RAW ZONE (dados brutos) simulada localmente.
│   └── WA_Fn-UseC_-Telco-Customer-Churn.csv  # Arquivo de referência.
├── dags/                            # Contém os scripts Python que definem os pipelines (DAGs) a serem executados pelo Airflow.
└── scripts/
    └── 02_generate_raw_data.py      # Script utilitário para gerar os dados brutos.
```

**Nota:** A pasta `data/` **é ignorada pelo Git** para evitar o versionamento de arquivos grandes, o que é uma má prática.

### 4.2. Configuração do Ambiente Local

Para trabalhar no projeto, siga os seguintes passos:

1. **Clone o repositório:**
    ```bash
    git clone [URL_DO_SEU_REPOSITORIO]
    cd projeto-churn
    ```
2. **Crie e ative o ambiente virtual:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```
3. **Instale as dependências:**
    ```bash
    # (Um arquivo requirements.txt será criado futuramente)
    pip install pandas faker tqdm
    ```

---

## 5. Dados do Datalake (Raw Zone)

Os dados brutos foram gerados sinteticamente para uma base de **80.000 clientes** usando o script `scripts/02_generate_raw_data.py`. Estes dados simulam múltiplas fontes de informação e foram carregados localmente.

### 5.1. Esquema dos Dados Gerados

* **`raw_customers.csv` (Fonte: CRM)**
    * `customer_id`: Identificador único do cliente (UUID).
    * `name`, `gender`, `birth_date`, `city`, `state`: Dados demográficos.
    * `join_date`: Data de ingresso do cliente.

* **`raw_subscriptions.csv` (Fonte: Billing)**
    * `subscription_id`, `customer_id`: Identificadores.
    * `tenure_months`: Tempo de permanência em meses.
    * `contract_type`, `payment_method`, `paperless_billing`: Detalhes do contrato.
    * `monthly_charges`: Valor da mensalidade.
    * `churn`: **Variável Alvo** (`Yes`/`No`).
    * *Colunas de serviços:* `PhoneService`, `MultipleLines`, `InternetService`, etc.

* **`raw_support_tickets.jsonl` (Fonte: Suporte)**
    * `ticket_id`, `customer_id`: Identificadores.
    * `created_at`: Data de criação do ticket.
    * `issue_type`, `status`, `priority`: Detalhes do ticket.

* **`raw_usage_logs.jsonl` (Fonte: Logs da Plataforma)**
    * `timestamp`: Data e hora do evento.
    * `customer_id`: Identificador do cliente.
    * `action`: Ação realizada (ex: `login`, `view_dashboard`).
    * `session_id`: Identificador da sessão.

---

## 6. Roadmap e Próximos Passos

Este documento reflete a conclusão das fases iniciais. O roadmap para as próximas etapas é:

1. **Fase 4 - Instalação e Configuração dos Serviços:**
    * [ ] Instalar o PostgreSQL, MinIO, Airflow, Superset e MLflow dentro dos seus respectivos containers LXC.
    * [ ] Configurar cada serviço para se comunicar com os outros através da rede privada `vmbr1` (ex: configurar a string de conexão do Airflow para o PostgreSQL).
    * [ ] Validar o acesso e a funcionalidade de cada serviço.

2. **Fase 5 - Desenvolvimento do Pipeline de ETL:**
    * [ ] Criar a primeira DAG (`dag_process_raw_data.py`) no diretório `dags/`.
    * [ ] A DAG será responsável por:
        1. Ler os 4 arquivos da `raw-zone` no MinIO.
        2. Realizar a limpeza (tratar valores nulos, corrigir tipos de dados).
        3. Agregar os dados de logs e tickets para criar features (ex: `total_logins_last_30_days`, `tickets_opened`).
        4. Unir todas as fontes de dados em uma única tabela de visão 360º do cliente.
        5. Salvar a tabela final na **`curated-zone`** do MinIO em formato **Parquet** (otimizado para análise).

3. **Fase 6 - Modelagem de Machine Learning:**
    * [ ] Desenvolver um script que lê os dados da `curated-zone`.
    * [ ] Utilizar o MLflow para rastrear experimentos de treinamento de um modelo de classificação (ex: Regressão Logística, XGBoost).
    * [ ] Avaliar as métricas do modelo e registrar a melhor versão no **MLflow Model Registry**.

4. **Fase 7 - Implantação e Visualização:**
    * [ ] Criar uma DAG de "batch scoring" para aplicar o modelo registrado a novos clientes.
    * [ ] Conectar o Superset aos dados da `curated-zone` e aos resultados da predição.
    * [ ] Construir um dashboard para monitorar a taxa de churn e visualizar os clientes com maior risco de cancelamento.
