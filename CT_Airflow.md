# Documentação de Configuração: Container Apache Airflow (CT 103) - Versão 3.0 (Estável)

**Hostname:** `airflow`  
**IP Privado:** `10.10.10.13`  
**Finalidade:** Orquestrador de pipelines de dados (ETL/ELT).

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 103
* **Hostname:** airflow
* **Recursos:**
    * **CPU Cores:** 4
    * **RAM:** 8 GB
    * **Disco:** 20 GB
* **Rede Principal (`net0`):**
    * **Bridge:** `vmbr1` (Rede Privada do Datalake)
    * **Tipo:** Estático
    * **Endereço IP:** `10.10.10.13/24`
    * **Gateway:** `10.10.10.1`
* **Rede Temporária (`net1` - *Removida após a instalação*):**
    * **Bridge:** `vmbr0` (Rede Principal/LAN)
    * **Tipo:** DHCP
    * **Finalidade:** Permitir acesso à internet para a instalação inicial de pacotes.

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

Este guia detalha o processo de instalação consolidado, incorporando as correções necessárias para um ambiente de produção estável.

### 2.1. Preparação do Ambiente do Container

1.  **Acesso à Internet Temporário:** Configurar uma rota e DNS para permitir o download de pacotes.

    ```bash
    ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    ```

2.  **Instalação de Dependências de Sistema:**

    ```bash
    apt update
    apt install -y libpq-dev build-essential python3-venv python3-pip graphviz locales
    ```

3.  **Configuração de Localização (Locale) para Suporte a UTF-8:** Este passo é **crítico** para evitar erros de `UnicodeEncodeError`.

    ```bash
    # Descomentar a localização en_US.UTF-8
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen

    # Gerar a localização
    locale-gen
    ```

### 2.2. Instalação Robusta do Airflow

1.  **Criação do Ambiente Virtual:**

    ```bash
    mkdir -p /opt/airflow/dags
    python3 -m venv /opt/airflow/venv
    source /opt/airflow/venv/bin/activate
    ```

2.  **Instalação com Arquivo de Restrições (Constraints):** Este é o método recomendado para evitar conflitos de dependência.

    ```bash
    export AIRFLOW_HOME=/opt/airflow
    echo "export AIRFLOW_HOME=/opt/airflow" >> ~/.bashrc
    pip install --upgrade pip wheel

    AIRFLOW_VERSION=2.8.1
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"

    # Instalar Airflow core e provedores necessários
    pip install "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"
    pip install "apache-airflow-providers-amazon" --constraint "${CONSTRAINT_URL}"
    ```

### 2.3. Configuração do `airflow.cfg`

1.  **Geração e Edição:** Gerar o arquivo com `airflow db init` (com a pasta `dags` vazia) e depois editar `$AIRFLOW_HOME/airflow.cfg` com as seguintes configurações:

    * **Seção `[core]`:**

      ```ini
      executor = LocalExecutor
      sql_alchemy_conn = postgresql+psycopg2://airflow:sua_senha_forte_para_airflow@10.10.10.11/airflow
      load_examples = False
      ```

    * **Seção `[webserver]`:**

      ```ini
      base_url = http://airflow.lan
      allowed_hosts = airflow.lan, localhost, 127.0.0.1
      ```

### 2.4. Inicialização do Banco de Dados e Criação de Usuário

* **Pré-requisito:** Garantir que o banco de dados `airflow` no PostgreSQL foi criado com codificação `UTF-8`.

* **Execução (com a pasta `dags` temporariamente vazia):**

  ```bash
  # Ativar o ambiente virtual e definir o locale para o terminal
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
  source /opt/airflow/venv/bin/activate

  # Inicializar o banco de dados
  airflow db init

  # Criar o usuário administrador
  airflow users create \
      --username admin --firstname Admin --lastname User \
      --role Admin --email admin@example.com
  ```

### 2.5. Configuração dos Serviços `systemd`

Os arquivos de serviço foram atualizados para incluir as variáveis de ambiente essenciais para a codificação e para a descoberta das DAGs.

1.  **`airflow-webserver.service`:** (`/etc/systemd/system/airflow-webserver.service`)

    ```ini
    [Unit]
    Description=Airflow Webserver
    After=network.target postgresql.service

    [Service]
    User=root
    Group=root
    Type=simple
    Environment="AIRFLOW_HOME=/opt/airflow"
    Environment="LANG=en_US.UTF-8"
    Environment="LC_ALL=en_US.UTF-8"
    Environment="AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags"
    ExecStart=/opt/airflow/venv/bin/airflow webserver
    Restart=on-failure
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    ```

2.  **`airflow-scheduler.service`:** (`/etc/systemd/system/airflow-scheduler.service`)

    * O conteúdo é idêntico ao do `webserver`, exceto pela linha `ExecStart`:

      ```ini
      ExecStart=/opt/airflow/venv/bin/airflow scheduler
      ```

### 2.6. Finalização

1.  **Ativação dos Serviços:**

    ```bash
    systemctl daemon-reload
    systemctl enable --now airflow-webserver airflow-scheduler
    ```

2.  **Remoção do Acesso à Internet:** A interface de rede temporária (`net1`) foi removida.

---

## 3. Estado Final

O container `airflow` (CT 103) está totalmente operacional e estável. A configuração de `locale`, a definição explícita da pasta de DAGs e a codificação correta do banco de dados garantem que o sistema funciona de forma confiável.

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

**Listar DAGs via CLI:**
```bash
source /opt/airflow/venv/bin/activate
airflow dags list
```

### Acesso à Interface Web

A interface web do Airflow está disponível através de:
- **URL:** `http://airflow.lan`
- **Usuário:** `admin`
- **Senha:** [definida durante a criação do usuário]

### Estrutura de Diretórios

```
/opt/airflow/
├── venv/                   # Ambiente virtual Python
├── airflow.cfg             # Arquivo de configuração
├── dags/                   # Local para colocar as DAGs do projeto
├── logs/                   # Logs da aplicação
└── (dados do banco no PostgreSQL)
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

---

## 6. Problemas Resolvidos e Lições Aprendidas

Durante a instalação, foram diagnosticados e resolvidos vários problemas complexos:

### Problema 1: Erros de dependência Python (`AttributeError`)

* **Causa:** Instalação de pacotes com versões incompatíveis
* **Solução:** Recriar o ambiente virtual e usar o arquivo de restrições (`--constraint`) para garantir a compatibilidade de todo o ecossistema de pacotes

### Problema 2: Erros de Codificação (`UnicodeEncodeError: 'ascii' codec...`)

* **Causa:** Uma falha em cascata. O arquivo da DAG continha caracteres UTF-8 (`é`), mas o ambiente do terminal, os serviços `systemd` e o banco de dados PostgreSQL estavam configurados por padrão para `ASCII`
* **Solução Multi-camada:**
  1. **Banco de Dados:** Recriar o banco de dados `airflow` no PostgreSQL com `ENCODING = 'UTF8'`
  2. **Sistema Operacional:** Instalar o pacote `locales` e gerar a localização `en_US.UTF-8`
  3. **Serviços `systemd`:** Adicionar as variáveis `LANG` e `LC_ALL` aos arquivos de serviço
  4. **DAG:** Recriar o arquivo .py para garantir que não continha metadados de codificação corrompidos

### Problema 3: DAG visível no CLI (`airflow dags list`) mas não na Interface Web

* **Causa:** O ambiente isolado do `systemd` não estava encontrando a pasta de DAGs, causando uma dessincronização entre o `scheduler` e o `webserver`
* **Solução:** Adicionar a variável de ambiente `Environment="AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow/dags"` explicitamente aos arquivos de serviço, eliminando qualquer ambiguidade

### Problema 4: Erro `Invalid Host header` ao acessar via proxy

* **Causa:** A aplicação Airflow não estava configurada para aceitar requisições do domínio `airflow.lan`
* **Solução:** Adicionar `allowed_hosts = airflow.lan, localhost, 127.0.0.1` no `airflow.cfg`

---

## 7. Configurações de Performance

### Otimização para Produção

```ini
# No airflow.cfg, ajustar para melhor performance:
[core]
parallelism = 32
dag_concurrency = 16
max_active_tasks_per_dag = 16

[scheduler]
max_threads = 4
scheduler_heartbeat_sec = 5

[webserver]
workers = 4
worker_class = sync
```

### Configuração de Conexão com MinIO

```python
# No Airflow, criar uma conexão do tipo Amazon S3:
# - Host: http://10.10.10.12:9000
# - Login: admin
# - Password: sua_senha_super_secreta_para_minio
# - Extra: {"region_name": "us-east-1"}
```

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O Airflow está funcionando corretamente e acessível via `http://airflow.lan`
