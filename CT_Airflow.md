# Documentação de Configuração: Container Apache Airflow (CT 103)

**Hostname:** `airflow`  
**IP:** `10.10.10.13`  
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
    * **Tipo:** Estático (Static)
    * **Endereço IP:** `10.10.10.13/24`
    * **Gateway:** `10.10.10.1`
* **Rede Temporária (`net1` - *Removida após a instalação*):**
    * **Bridge:** `vmbr0` (Rede Principal/LAN)
    * **Tipo:** DHCP

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

### 2.1. Habilitação Temporária de Acesso à Internet

Foi configurada uma rota padrão e DNS temporários para permitir o download de pacotes. Este passo é revertido ao remover a interface `net1`.

```bash
# Adicionar rota padrão para o gateway da LAN
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1

# Configurar DNS público
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Instalação de Dependências de Sistema

```bash
apt update
apt install -y libpq-dev build-essential python3-venv python3-pip graphviz
```

* `graphviz` foi incluído para corrigir um aviso do Airflow e permitir a renderização gráfica das DAGs na interface web.

### 2.3. Criação de Ambiente Virtual e Instalação do Airflow

1.  **Criação do Ambiente:** Para isolar as dependências do Python, foi criado um ambiente virtual em `/opt/airflow/venv`.

    ```bash
    mkdir -p /opt/airflow
    python3 -m venv /opt/airflow/venv
    source /opt/airflow/venv/bin/activate
    ```

2.  **Instalação do Airflow e Dependências:**

    ```bash
    export AIRFLOW_HOME=/opt/airflow
    echo "export AIRFLOW_HOME=/opt/airflow" >> ~/.bashrc

    AIRFLOW_VERSION=2.8.1
    pip install "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}"
    ```

3.  **(CORREÇÃO) Corrigir Incompatibilidades de Dependência:** Após a instalação inicial, foram encontrados erros de importação nas DAGs de exemplo. As seguintes dependências foram instaladas para corrigir os problemas:

    ```bash
    # Corrige o erro "ModuleNotFoundError: No module named 'flask_session.sessions'"
    pip install "flask-session==0.5.0"

    # Corrige o erro "AirflowException: PythonVirtualenvOperator requires virtualenv"
    pip install virtualenv
    ```

### 2.4. Configuração do Banco de Dados e DAGs de Exemplo

1.  **Inicialização Inicial:** O comando `airflow db init` foi executado uma vez para gerar o arquivo de configuração `airflow.cfg`.

2.  **Edição do `airflow.cfg`:** O arquivo `$AIRFLOW_HOME/airflow.cfg` foi editado com as seguintes alterações:

    * Alterar `executor = SequentialExecutor` para `executor = LocalExecutor`.
    * Alterar `sql_alchemy_conn` para a string de conexão do PostgreSQL:
      ```ini
      sql_alchemy_conn = postgresql+psycopg2://airflow:sua_senha_forte_para_airflow@10.10.10.11/airflow
      ```
    * Desativar as DAGs de exemplo para evitar futuros erros de importação e manter o ambiente limpo:
      ```ini
      load_examples = False
      ```

3.  **Inicialização Final:** O comando `airflow db init` foi executado novamente para popular o banco de dados no PostgreSQL com a configuração correta.

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

O container `airflow` (CT 103) está totalmente operacional, com os serviços `webserver` e `scheduler` executando de forma autônoma e gerenciados pelo `systemd`. A instalação está limpa, sem DAGs de exemplo, e pronta para receber os pipelines de dados do projeto no diretório `/opt/airflow/dags`.

**Acesso à Interface Web:**  
O Airflow Webserver está acessível via navegador no endereço `http://10.10.10.13:8080`. Utilize as credenciais do usuário `admin` criado para fazer login.

**Verificação do Status dos Serviços:**
```bash
systemctl status airflow-webserver
systemctl status airflow-scheduler
```

**Logs dos Serviços:**
```bash
journalctl -u airflow-webserver -f
journalctl -u airflow-scheduler -f
```
