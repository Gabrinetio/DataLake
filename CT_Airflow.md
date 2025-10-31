# Documentação Consolidada de Configuração: Contentor Apache Airflow (CT 103)

## Identificação e Finalidade
- **ID do Contentor:** 103
- **Hostname:** `airflow`
- **Endereço IP:** `10.10.10.13/24`
- **Finalidade:** Orquestrador de pipelines de dados (ETL/ELT) para automatização e gestão de fluxos de trabalho de dados.

---

## Especificações Técnicas do Contentor

### Recursos Alocados
- **CPU Cores:** 4
- **RAM:** 8 GB
- **Armazenamento:** 20 GB
- **Sistema Base:** Debian 12 (clonado do template `debian-12-template`)

### Configuração de Rede
- **Rede Principal (`net0`):**
  - **Bridge:** `vmbr1` (Rede Privada do Datalake)
  - **Tipo:** Estático
  - **IP:** `10.10.10.13/24`
  - **Gateway:** `10.10.10.1`

- **Rede Temporária (`net1`):**
  - **Status:** Removida após instalação
  - **Bridge:** `vmbr0` (Rede Principal/LAN)
  - **Tipo:** DHCP
  - **Finalidade:** Acesso temporário à internet para instalação

---

## Processo de Instalação e Configuração

### 1. Configuração Temporária de Rede para Internet
```bash
# Configurar rota padrão temporária
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1

# Configurar DNS temporário
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2. Instalação de Dependências do Sistema
```bash
# Atualizar repositórios e instalar dependências essenciais
apt update
apt install -y libpq-dev build-essential python3-venv python3-pip
```

### 3. Configuração do Ambiente Python

**Estratégia:** Utilização de ambiente virtual para isolamento de dependências

```bash
# Criar diretório principal do Airflow
mkdir -p /opt/airflow

# Criar ambiente virtual Python
python3 -m venv /opt/airflow/venv

# Ativar ambiente virtual
source /opt/airflow/venv/bin/activate
```

### 4. Instalação do Apache Airflow

```bash
# Definir variável de ambiente do Airflow
export AIRFLOW_HOME=/opt/airflow
echo "export AIRFLOW_HOME=/opt/airflow" >> ~/.bashrc

# Definir versão específica para consistência
AIRFLOW_VERSION=2.8.1

# Instalar Airflow com extras para PostgreSQL e S3
pip install "apache-airflow[postgres,s3]==${AIRFLOW_VERSION}"
```

### 5. Configuração da Base de Dados

**Processo de Configuração em Duas Fases:**

1. **Inicialização Preliminar:**
```bash
# Criar configuração base (airflow.cfg)
airflow db init
```

2. **Configuração Avançada:**

**Ficheiro:** `$AIRFLOW_HOME/airflow.cfg`
```ini
# Executor para paralelização de tarefas
executor = LocalExecutor

# Conexão com PostgreSQL (substituir pela senha real)
sql_alchemy_conn = postgresql+psycopg2://airflow:sua_senha_forte_para_airflow@10.10.10.11/airflow
```

3. **Inicialização Final:**
```bash
# Popular base de dados PostgreSQL com esquema do Airflow
airflow db init
```

### 6. Criação de Utilizador Administrador
```bash
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com
```
*Senha definida interativamente durante a execução*

### 7. Inicialização dos Serviços

**Arquitetura de Serviços:**
- **Webserver (Porta 8080):** Interface web de gestão
- **Scheduler:** Serviço de agendamento e execução de DAGs

```bash
# Terminal 1 - Webserver
source /opt/airflow/venv/bin/activate
airflow webserver

# Terminal 2 - Scheduler  
source /opt/airflow/venv/bin/activate
airflow scheduler
```

---

## Integrações Configuradas

### Backend de Base de Dados
- **Serviço:** PostgreSQL (CT 101)
- **Base de Dados:** `airflow`
- **Utilizador:** `airflow`
- **Finalidade:** Armazenamento de metadados, DAGs, histórico de execuções

### Conectividade de Rede
- **Acesso à Rede:** `10.10.10.0/24`
- **Serviços Expostos:**
  - **Web Interface:** Porta 8080
  - **API:** Porta 8080 (via webserver)

---

## Configuração de Segurança

### Medidas Implementadas
- ✅ Ambiente virtual Python para isolamento de dependências
- ✅ Execução com configuração dedicada em `/opt/airflow`
- ✅ Autenticação via utilizador/password para interface web
- ✅ Isolamento de rede após instalação
- ✅ Comunicação segura com PostgreSQL via rede privada

### Credenciais de Acesso
- **Utilizador Web:** `admin`
- **Password:** Definida durante criação do utilizador
- **Âmbito:** Acesso apenas na rede privada do datalake

---

## Estado Final do Serviço

### Status Operacional
- ✅ Serviço Airflow instalado e configurado
- ✅ Ambiente virtual Python ativo
- ✅ Base de dados PostgreSQL configurada como backend
- ✅ Serviços webserver e scheduler em execução
- ✅ Interface web acessível na porta 8080

### Componentes em Execução
| Componente | Estado | Finalidade |
|------------|---------|------------|
| **Webserver** | ✅ Ativo | Interface web na porta 8080 |
| **Scheduler** | ✅ Ativo | Orquestração de DAGs e tarefas |
| **Database** | ✅ Configurado | Metadados no PostgreSQL |

---

## Arquitetura do Airflow

### Executor Configurado: LocalExecutor
- **Tipo:** `LocalExecutor`
- **Vantagens:** Execução paralela de tarefas
- **Limitações:** Escalabilidade limitada ao contentor
- **Adequação:** Ideal para ambiente de desenvolvimento/pequena produção

### Estrutura de Diretórios
```
/opt/airflow/
├── venv/                 # Ambiente virtual Python
├── airflow.cfg          # Configuração principal
├── dags/               # Diretório para DAGs (a criar)
├── logs/               # Logs de execução
└── airflow.db          # (Não utilizado - substituído por PostgreSQL)
```

---

## Próximos Passos e Desenvolvimento

### Ações Imediatas
1. **Desenvolvimento de DAGs:** Criar pipelines no diretório `$AIRFLOW_HOME/dags/`
2. **Configuração de Conexões:** Definir conexões com MinIO e outros serviços
3. **Monitorização:** Configurar alertas e monitorização dos serviços

### Expansões Futuras
- **Escalabilidade:** Migração para CeleryExecutor ou KubernetesExecutor
- **Segurança:** Implementação de SSL/TLS
- **Alta Disponibilidade:** Configuração de múltiplos schedulers
- **Integração:** Conexão com mais serviços do ecossistema de dados

---

## Acesso e Utilização

### Interface Web
- **URL:** `http://10.10.10.13:8080`
- **Credenciais:** Utilizador `admin` + password definida
- **Rede:** Acesso apenas da VLAN privada `10.10.10.0/24`

### Gestão de Serviços
```bash
# Com ambiente virtual ativo
source /opt/airflow/venv/bin/activate

# Comandos de gestão
airflow webserver    # Iniciar interface web
airflow scheduler    # Iniciar agendador
airflow dags list    # Listar DAGs disponíveis
```

*Documentação atualizada em: [Data da última atualização]*

**Nota:** O Airflow serve como o cérebro do pipeline de dados, orquestrando todas as operações entre os diferentes componentes do datalake.
````
