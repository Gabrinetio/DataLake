# Projeto: Plataforma Preditiva de Churn (Auto-hospedado)

**Versão:** 1.2 (Fase de Instalação dos Serviços Core)
**Data:** 1 de Novembro de 2025
**Stack Principal:** Proxmox, Debian 12 (LXC), Nginx Proxy Manager, Python, Git

---

## 1. Visão Geral do Projeto

Este repositório contém o código e a documentação para a construção de uma plataforma de dados ponta a ponta, totalmente auto-hospedada, com o objetivo de prever o **churn (cancelamento) de clientes**. A plataforma é construída sobre uma stack 100% open-source, com a infraestrutura virtualizada em **Proxmox VE**, e segue os princípios de uma arquitetura de **Datalake** moderna.

---

## 2. Stack de Tecnologias

| Componente | Ferramenta Open-Source | Papel no Projeto |
| :--- | :--- | :--- |
| **Virtualização** | Proxmox VE | Camada de IaaS para criar e gerenciar os servidores virtuais. |
| **Sistema Operacional**| Debian 12 "Bookworm" | SO base para todos os containers (CTs LXC). |
| **Gateway/Proxy** | Nginx Proxy Manager | Ponto de entrada seguro para acessar às interfaces web dos serviços. |
| **Armazenamento** | MinIO | Datalake físico (Object Storage) para `raw-zone` e `curated-zone`. |
| **Banco de Dados** | PostgreSQL | Backend metastore para Airflow, Superset e MLflow. |
| **Orquestração** | Apache Airflow | Ferramenta para agendar, executar e monitorar pipelines de dados. |
| **MLOps** | MLflow | (Futuro) Plataforma para gerenciar o ciclo de vida dos modelos de Machine Learning. |
| **Visualização (BI)**| Apache Superset | (Futuro) Ferramenta para criar dashboards e visualizar os dados. |

---

## 3. Arquitetura da Infraestrutura (Proxmox)

A infraestrutura é composta por containers LXC isolados em uma rede privada (`vmbr1` - `10.10.10.0/24`) para maior segurança e eficiência. O acesso externo é gerenciado por um gateway dedicado.

| ID | Hostname | Finalidade | IP (em `vmbr1`) | Status |
| :- | :--- | :--- | :---------------- | :--- |
| `101`| `postgres` | Banco de Dados | `10.10.10.11/24` | ✅ **Concluído** |
| `102`| `minio` | Datalake Storage | `10.10.10.12/24` | ✅ **Concluído** |
| `103`| `airflow` | Orquestração | `10.10.10.13/24` | ✅ **Concluído** |
| `104`| `superset` | Business Intelligence | `10.10.10.14/24` | ⏳ A fazer |
| `105`| `mlflow` | MLOps | `10.10.10.15/24` | ⏳ A fazer |
| `106`| `gateway` | Reverse Proxy | `10.10.10.106/24`| ✅ **Concluído** |

---

## 4. Guia de Instalação e Configuração

Documentos detalhados para a configuração de cada container estão disponíveis no repositório:
* `docs/CT101_POSTGRES_SETUP.md`
* `docs/CT102_MINIO_SETUP.md`
* `docs/CT103_AIRFLOW_SETUP.md`
* `docs/CT106_GATEWAY_SETUP.md`

O acesso à interface do Airflow está agora disponível em **`http://airflow.lan`** através do gateway.

---

## 5. Roadmap e Próximos Passos

A infraestrutura base está agora operacional. As próximas fases são:

1.  **Fase 4 - Instalação e Configuração (Continuação):**
    * [ ] Instalar e configurar o **Apache Superset** no CT 104.
    * [ ] Instalar e configurar o **MLflow** no CT 105.
    * [ ] Adicionar as rotas para Superset e MLflow no Nginx Proxy Manager.

2.  **Fase 5 - Desenvolvimento do Pipeline de ETL:**
    * [ ] Criar a primeira DAG para ler os dados brutos do MinIO, transformá-los e salvá-los de volta no MinIO em formato Parquet, em uma zona curada.

3.  **Fase 6 - Modelagem de Machine Learning:**
    * [ ] Desenvolver scripts para treinar modelos usando os dados curados, com tracking de experiências no MLflow.

4.  **Fase 7 - Implantação e Visualização:**
    * [ ] Criar uma DAG de "batch scoring" para aplicar o modelo registrado a novos clientes.
    * [ ] Construir dashboards no Superset.

---

# Documentação de Configuração: Container Apache Airflow (CT 103)

**Hostname:** `airflow`  
**IP Privado:** `10.10.10.13`  
**Finalidade:** Orquestrador de pipelines de dados (ETL/ELT).

---

## 1. Configuração do Container (CT) no Proxmox

Este container foi clonado a partir do template `debian-12-template`.

* **ID:** 103
* **Hostname:** airflow
* **Recursos:** 4 Cores, 8GB RAM, 20GB Disco
* **Rede Principal (`net0`):** Bridge `vmbr1`, IP Estático `10.10.10.13/24`.
* **Rede Temporária (`net1`):** Bridge `vmbr0`, DHCP (removida após a instalação).

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

### 2.1. Habilitação Temporária de Acesso à Internet

Foi configurada uma rota padrão e DNS temporários para permitir o download de pacotes.

```bash
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Instalação de Dependências de Sistema

```bash
apt update
apt install -y libpq-dev build-essential python3-venv python3-pip graphviz
```

### 2.3. Criação de Ambiente Virtual e Instalação do Airflow

1.  **Criação do Ambiente e Reinstalação Corretiva:** Devido a problemas de dependências e arquivos faltando na primeira instalação, o ambiente virtual foi recriado e o Airflow foi reinstalado com um único comando para garantir a resolução correta das dependências.
    ```bash
    # Remover ambiente corrompido (se existir)
    rm -rf /opt/airflow/venv

    # Recriar ambiente
    mkdir -p /opt/airflow
    python3 -m venv /opt/airflow/venv
    source /opt/airflow/venv/bin/activate
    ```
2.  **Instalação do Airflow e Dependências Corretivas:**
    ```bash
    export AIRFLOW_HOME=/opt/airflow
    echo "export AIRFLOW_HOME=/opt/airflow" >> ~/.bashrc

    AIRFLOW_VERSION=2.8.1
    pip install "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}" "flask-session==0.5.0" "virtualenv"
    ```
      * `flask-session==0.5.0`: Corrige a incompatibilidade `No module named 'flask_session.sessions'`.
      * `virtualenv`: Corrige a dependência faltando para o `PythonVirtualenvOperator`.

### 2.4. Configuração do Banco de Dados e DAGs de Exemplo

1.  **Inicialização Inicial:** `airflow db init` foi executado para gerar o arquivo `airflow.cfg`.
2.  **Edição do `airflow.cfg`:** O arquivo `$AIRFLOW_HOME/airflow.cfg` foi editado:
      * `executor = LocalExecutor`
      * `sql_alchemy_conn = postgresql+psycopg2://airflow:sua_senha_forte_para_airflow@10.10.10.11/airflow`
      * `load_examples = False` (para evitar erros de importação e manter o ambiente limpo).
3.  **Inicialização Final:** `airflow db init` foi executado novamente para popular o banco de dados no PostgreSQL.

### 2.5. Criação de Usuário Admin

```bash
# Executado dentro do ambiente virtual
airflow users create --username admin --firstname Admin --lastname User --role Admin --email admin@gabrielti.com.br
```

### 2.6. Criação dos Serviços `systemd`

Para garantir que o Airflow execute como um serviço autônomo, foram criados dois arquivos de serviço, corrigindo o caminho do executável para `/opt/airflow/venv/bin/airflow`.

1.  **`airflow-webserver.service`** (`/etc/systemd/system/`):

    ```ini
    [Unit]
    Description=Airflow Webserver
    After=network.target postgresql.service

    [Service]
    User=root
    Group=root
    Type=simple
    Environment="AIRFLOW_HOME=/opt/airflow"
    ExecStart=/opt/airflow/venv/bin/airflow webserver
    Restart=on-failure
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    ```

2.  **`airflow-scheduler.service`** (`/etc/systemd/system/`):

    ```ini
    [Unit]
    Description=Airflow Scheduler
    After=network.target postgresql.service

    [Service]
    User=root
    Group=root
    Type=simple
    Environment="AIRFLOW_HOME=/opt/airflow"
    ExecStart=/opt/airflow/venv/bin/airflow scheduler
    Restart=on-failure
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    ```

### 2.7. Finalização

1.  **Ativação dos Serviços:**
    ```bash
    systemctl daemon-reload
    systemctl enable --now airflow-webserver
    systemctl enable --now airflow-scheduler
    ```
2.  **Remoção do Acesso à Internet:** A interface de rede temporária (`net1`) foi removida na UI do Proxmox.

---

## 3. Estado Final

O container `airflow` (CT 103) está totalmente operacional. O acesso à interface web é feito através do Reverse Proxy (Gateway) no endereço **`http://airflow.lan`**.

---

## 4. Verificação e Monitoramento

### Comandos Úteis

**Verificar status dos serviços:**
```bash
systemctl status airflow-webserver
systemctl status airflow-scheduler
```

**Ver logs em tempo real:**
```bash
journalctl -u airflow-webserver -f
journalctl -u airflow-scheduler -f
```

**Verificar se os processos estão em execução:**
```bash
ps aux | grep airflow
```

### Acesso à Interface Web

A interface web do Airflow está disponível através de:
- **URL:** `http://airflow.lan`
- **Usuário:** `admin`
- **Senha:** [definida durante a criação do usuário]

### Estrutura de Diretórios

```
/opt/airflow/
├── venv/           # Ambiente virtual Python
├── airflow.cfg     # Arquivo de configuração
├── airflow.db      # (Não utilizado - banco em PostgreSQL)
├── logs/           # Logs da aplicação
└── dags/           # Local para colocar as DAGs do projeto
```

---

## 5. Próximos Passos

1. **Desenvolvimento de DAGs:** Começar a desenvolver e implantar DAGs no diretório `/opt/airflow/dags`
2. **Configuração de Conexões:** Configurar conexões com outros serviços (MinIO, PostgreSQL, etc.) através da UI web
3. **Variáveis de Ambiente:** Definir variáveis de ambiente para configurações sensíveis
4. **Monitoramento:** Implementar monitoramento e alertas para as DAGs e serviços
5. **Backup:** Configurar backup regular do banco de dados PostgreSQL

### Comando para Reiniciar Serviços

```bash
# Reiniciar ambos os serviços
systemctl restart airflow-webserver airflow-scheduler

# Verificar status após reinício
systemctl status airflow-webserver airflow-scheduler
```

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O Airflow está funcionando corretamente e acessível via `http://airflow.lan`.
