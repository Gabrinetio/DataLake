# Documentação de Configuração: Container Apache Superset (CT 104)

**Hostname:** `superset`  
**IP Privado:** `10.10.10.14`  
**Finalidade:** Ferramenta de Business Intelligence (BI) para exploração, visualização de dados e criação de dashboards.

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 104
* **Hostname:** superset
* **Recursos:** 2 Cores, 4GB RAM, 20GB Disco
* **Rede Principal (`net0`):** Bridge `vmbr1`, IP Estático `10.10.10.14/24`
* **Rede Temporária (`net1`):** Bridge `vmbr0`, DHCP (removida após a instalação)

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

### 2.1. Habilitação Temporária de Acesso à Internet

Foi configurada uma rota padrão e DNS temporários para permitir o download de pacotes.

```bash
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Instalação de Dependências de Sistema

Foram instalados os pacotes necessários para compilação e para a conexão com o PostgreSQL.

```bash
apt update
apt install -y build-essential libffi-dev python3-dev python3-pip python3-venv libpq-dev
```

### 2.3. Instalação do Superset

O Superset foi instalado via `pip` dentro de um ambiente virtual isolado em `/opt/superset/venv`.

```bash
# Criar ambiente virtual
mkdir -p /opt/superset
python3 -m venv /opt/superset/venv
source /opt/superset/venv/bin/activate

# Instalar Apache Superset
pip install apache-superset
```

### 2.4. Arquivo de Configuração

Um arquivo de configuração foi criado em `/opt/superset/superset_config.py` com as seguintes definições essenciais:

```python
# Arquivo: /opt/superset/superset_config.py

# 1. Chave secreta gerada com: openssl rand -base64 42
SECRET_KEY = 'SUA_CHAVE_SECRETA_SUPER_LONGA_E_ALEATORIA_AQUI'

# 2. Configuração da conexão com o PostgreSQL
SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://superset:sua_senha_forte_para_superset@10.10.10.11/superset'

# 3. Habilita funcionalidades adicionais
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "CSV_UPLOAD": True,
}
```

### 2.5. Configuração do Ambiente

```bash
# Definir variável de ambiente para o arquivo de configuração
export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py
echo "export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py" >> ~/.bashrc
```

### 2.6. Inicialização do Banco de Dados

Os seguintes comandos foram executados para preparar a aplicação:

```bash
# Atualizar banco de dados
superset db upgrade

# Criar usuário administrador
superset fab create-admin

# Inicializar roles e permissões
superset init
```

### 2.7. Serviço `systemd`

Um serviço `systemd` foi criado em `/etc/systemd/system/superset.service` para gerenciar a aplicação em produção, usando `gunicorn` como servidor WSGI.

```ini
[Unit]
Description=Superset Web Server
After=network.target

[Service]
PIDFile=/run/superset/pid
User=superset
Group=superset
WorkingDirectory=/opt/superset/venv/bin
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
# Criar usuário de sistema
useradd -r -s /bin/false superset
chown -R superset:superset /opt/superset

# Ativar serviço
systemctl daemon-reload
systemctl enable --now superset.service
```

### 2.8. Finalização

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

O container `superset` (CT 104) está totalmente operacional. O acesso à interface web é feito através do Reverse Proxy (Gateway) no endereço **`http://superset.lan`**.

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
└── (dados do banco no PostgreSQL)
```

---

## 6. Próximos Passos

1. **Configurar Fontes de Dados:** Conectar o Superset ao PostgreSQL e MinIO
2. **Criar Dashboards:** Desenvolver visualizações e dashboards para análise de dados
3. **Configurar Segurança:** Definir roles e permissões para usuários
4. **Integração com Airflow:** Configurar atualizações automáticas de dados
5. **Backup:** Configurar backup regular das configurações e metadados

### Comandos para Solução de Problemas

**Verificar se o serviço está ouvindo na porta correta:**
```bash
netstat -tlnp | grep 8088
```

**Testar conexão com o banco de dados:**
```bash
# Dentro do ambiente virtual
python -c "
from superset.app import create_app
app = create_app()
with app.app_context():
    from superset import db
    print('Conexão com o banco OK')
"
```

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O Superset está funcionando corretamente e acessível via `http://superset.lan`.
