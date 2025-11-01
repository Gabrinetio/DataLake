# Documentação de Configuração: Container Apache Superset (CT 104)

**Hostname:** `superset`  
**IP Privado:** `10.10.10.14`  
**Finalidade:** Ferramenta de Business Intelligence (BI) para exploração, visualização de dados e criação de dashboards.

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 104
* **Hostname:** superset
* **Recursos:** 2 Cores, 4GB RAM, 20GB Disco
* **Rede:** `10.10.10.14/24` em `vmbr1`
* **Template Base:** `debian-12-template`

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

Esta seção detalha o processo completo, incluindo as correções aplicadas durante a depuração.

### 2.1. Habilitação Temporária de Acesso à Internet

```bash
# Configurar rota padrão temporária
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Dependências de Sistema

Foram instalados os pacotes necessários para a compilação de módulos Python e para a conexão com o PostgreSQL.

```bash
apt update
apt install -y build-essential libffi-dev python3-dev python3-pip python3-venv libpq-dev
```

### 2.3. Instalação do Superset e Dependências

O Superset foi instalado via `pip` dentro de um ambiente virtual isolado em `/opt/superset/venv`.

```bash
# Criação do ambiente
mkdir -p /opt/superset
python3 -m venv /opt/superset/venv
source /opt/superset/venv/bin/activate

# Instalação do Superset
pip install apache-superset

# Instalação de dependências para corrigir erros de inicialização
pip install psycopg2-binary
pip install "marshmallow<4.0.0" "marshmallow-sqlalchemy<1.0.0" "sqlalchemy-utils<0.39.0"
```

* `psycopg2-binary`: Corrige o erro `ModuleNotFoundError: No module named 'psycopg2'`
* `marshmallow<4.0.0` e relacionados: Corrigem o erro `TypeError: Field.__init__() got an unexpected keyword argument 'minLength'`

### 2.4. Arquivo de Configuração

Um arquivo de configuração foi criado em `/opt/superset/superset_config.py`:

```python
# Arquivo: /opt/superset/superset_config.py

# 1. Chave secreta gerada com: openssl rand -base64 42
SECRET_KEY = 'SUA_CHAVE_SECRETA_SUPER_LONGA_E_ALEATORIA_AQUI'

# 2. Configuração da conexão com o PostgreSQL (senha codificada para URL)
SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://superset:sua_senha_forte_para_superset@10.10.10.11/superset'

# 3. Habilita funcionalidades adicionais
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "CSV_UPLOAD": True,
}

# 4. Define diretório de dados para resolver erro de permissão
DATA_DIR = '/opt/superset/data'
```

### 2.5. Inicialização da Aplicação

Os seguintes comandos foram executados para preparar a aplicação:

```bash
# Definir variáveis de ambiente
export FLASK_APP=superset
export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py

# Criar diretório de dados
mkdir -p /opt/superset/data

# Inicializa/Atualiza o esquema do banco de dados
superset db upgrade

# Cria o usuário administrador
superset fab create-admin

# Inicializa os roles e permissões padrão
superset init
```

### 2.6. Serviço `systemd`

Um serviço `systemd` foi criado em `/etc/systemd/system/superset.service` para gerenciar a aplicação em produção, usando `gunicorn`. O arquivo foi ajustado para especificar o `WorkingDirectory=/opt/superset` para corrigir um erro de permissão na inicialização.

```ini
[Unit]
Description=Superset Web Server
After=network.target

[Service]
PIDFile=/run/superset/pid
User=superset
Group=superset
WorkingDirectory=/opt/superset
Environment="FLASK_APP=superset"
Environment="SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py"
ExecStart=/opt/superset/venv/bin/gunicorn \
    --workers 4 \
    --bind 0.0.0.0:8088 \
    --timeout 120 \
    'superset.app:create_app()'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Comandos de ativação do serviço:**
```bash
# Criação do usuário de sistema
useradd -r -s /bin/false superset
chown -R superset:superset /opt/superset

# Ativação do serviço
systemctl daemon-reload
systemctl enable --now superset.service
```

### 2.7. Finalização

A interface de rede temporária (`net1`) foi removida na UI do Proxmox após a conclusão da instalação.

---

## 3. Configuração do Gateway

### Proxy Host no Nginx Proxy Manager

* **Domain Names:** `superset.lan`
* **Forward Hostname / IP:** `10.10.10.14`
* **Forward Port:** `8088`

### Configuração de DNS Local

Adicione a seguinte linha ao arquivo `hosts` da máquina cliente:
```
192.168.1.106   superset.lan
```

---

## 4. Estado Final

O container `superset` (CT 104) está totalmente operacional. O serviço está executando de forma autônoma e o acesso à interface web é feito através do Reverse Proxy (Gateway) no endereço **`http://superset.lan`**.

---

## 5. Verificação e Monitoramento

### Comandos Úteis

**Verificar status do serviço:**
```bash
systemctl status superset.service
```

**Ver logs em tempo real:**
```bash
journalctl -u superset.service -f
```

**Reiniciar o serviço:**
```bash
systemctl restart superset.service
```

**Testar se a aplicação está respondendo:**
```bash
curl -I http://localhost:8088
```

### Acesso à Interface Web

A interface web do Superset está disponível através de:
- **URL:** `http://superset.lan`
- **Usuário:** `admin` (ou o usuário criado durante a configuração)
- **Senha:** [definida durante a criação do usuário administrador]

### Estrutura de Diretórios

```
/opt/superset/
├── venv/                   # Ambiente virtual Python
├── superset_config.py      # Arquivo de configuração
├── data/                   # Diretório de dados da aplicação
└── (dados do banco no PostgreSQL)
```

---

## 6. Problemas Resolvidos

### Erro: `ModuleNotFoundError: No module named 'psycopg2'`
**Solução:** Instalação do pacote `psycopg2-binary`

### Erro: `TypeError: Field.__init__() got an unexpected keyword argument 'minLength'`
**Solução:** Instalação de versões específicas dos pacotes marshmallow

### Erro: `Permission denied: '/home/superset'`
**Solução:** Configuração do `DATA_DIR` no arquivo de configuração

### Erro de permissão no serviço systemd
**Solução:** Ajuste do `WorkingDirectory` no serviço systemd

---

## 7. Próximos Passos

1. **Configurar Fontes de Dados:** Conectar o Superset ao PostgreSQL e MinIO
2. **Criar Dashboards:** Desenvolver visualizações e dashboards para análise de dados
3. **Configurar Segurança:** Definir roles e permissões para usuários
4. **Integração com Airflow:** Configurar atualizações automáticas de dados
5. **Backup:** Configurar backup regular das configurações e metadados

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O Superset está funcionando corretamente e acessível via `http://superset.lan`.
