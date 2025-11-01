# Documentação de Configuração: Container Apache Airflow (CT 103)

**Hostname:** `airflow`  
**IP Privado:** `10.10.10.13`  
**Finalidade:** Orquestrador de pipelines de dados (ETL/ELT).

---

## 1. Configuração do Container (CT) no Proxmox

Este container foi clonado a partir do template `debian-12-template`.

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

Os seguintes comandos foram executados no console do CT 103 para instalar e configurar o serviço Apache Airflow.

### 2.1. Habilitação Temporária de Acesso à Internet

Para permitir o download de pacotes, foi necessário configurar temporariamente uma rota de saída para a internet.

```bash
# Adicionar rota padrão para o gateway da LAN (ex: 192.168.1.1)
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1

# Configurar um servidor DNS público
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Instalação de Dependências de Sistema

```bash
apt update
apt install -y libpq-dev build-essential python3-venv python3-pip graphviz
```

* `graphviz` foi incluído para permitir a renderização da visualização "Graph" na interface web do Airflow.

### 2.3. Criação de Ambiente Virtual e Instalação do Airflow

1.  **Criação do Ambiente:** Para isolar as dependências do Python, foi criado um ambiente virtual em `/opt/airflow/venv`.

    ```bash
    mkdir -p /opt/airflow
    python3 -m venv /opt/airflow/venv
    source /opt/airflow/venv/bin/activate
    ```

2.  **Instalação do Airflow e Dependências Corretivas:** A instalação foi feita em um único comando para ajudar o `pip` a resolver as dependências corretamente desde o início.

    ```bash
    export AIRFLOW_HOME=/opt/airflow
    echo "export AIRFLOW_HOME=/opt/airflow" >> ~/.bashrc

    AIRFLOW_VERSION=2.8.1
    pip install "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}" "flask-session==0.5.0" "virtualenv"
    ```

    * `flask-session==0.5.0`: Corrige uma incompatibilidade de versão que causa o erro `No module named 'flask_session.sessions'`.
    * `virtualenv`: Corrige um erro nas DAGs de exemplo que utilizam o `PythonVirtualenvOperator`.

### 2.4. Configuração do Banco de Dados e DAGs de Exemplo

1.  **Inicialização Inicial:** O comando `airflow db init` foi executado uma vez para gerar o arquivo de configuração.
2.  **Edição do `airflow.cfg`:** O arquivo `$AIRFLOW_HOME/airflow.cfg` foi editado com as seguintes alterações:
    * Alterar o executor para permitir paralelismo:
      ```ini
      executor = LocalExecutor
      ```
    * Alterar a conexão do banco de dados para apontar para o PostgreSQL:
      ```ini
      sql_alchemy_conn = postgresql+psycopg2://airflow:sua_senha_forte_para_airflow@10.10.10.11/airflow
      ```
    * Desativar as DAGs de exemplo para evitar erros de importação e manter o ambiente limpo:
      ```ini
      load_examples = False
      ```
3.  **Inicialização Final:** O comando `airflow db init` foi executado novamente para popular o banco de dados no PostgreSQL.

### 2.5. Criação de Usuário Admin

O usuário `admin` foi criado para acessar a interface web:

```bash
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@gabrielti.com.br
```

(A senha foi definida interativamente).

### 2.6. Criação dos Serviços `systemd`

Para garantir que o Airflow execute como um serviço autônomo em segundo plano, foram criados dois arquivos de serviço `systemd`.

1.  **`airflow-webserver.service`:**

    * **Localização:** `/etc/systemd/system/airflow-webserver.service`
    * **Conteúdo:**
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

2.  **`airflow-scheduler.service`:**

    * **Localização:** `/etc/systemd/system/airflow-scheduler.service`
    * **Conteúdo:**
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

1.  **Ativação dos Serviços:** Os serviços foram recarregados, ativados para iniciar na inicialização do sistema e iniciados imediatamente:

    ```bash
    systemctl daemon-reload
    systemctl enable --now airflow-webserver
    systemctl enable --now airflow-scheduler
    ```

2.  **Remoção do Acesso à Internet:** A interface de rede temporária (`net1`) foi removida na UI do Proxmox.

---

## 3. Estado Final

O container `airflow` (CT 103) está totalmente operacional, com os serviços `webserver` e `scheduler` executando de forma autônoma e gerenciados pelo `systemd`. A instalação está limpa, sem DAGs de exemplo, e pronta para receber os pipelines de dados do projeto no diretório `/opt/airflow/dags`. O acesso à interface web é feito através do Reverse Proxy (Gateway) no endereço `http://airflow.lan`.

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

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O Airflow está funcionando corretamente e acessível via `http://airflow.lan`
