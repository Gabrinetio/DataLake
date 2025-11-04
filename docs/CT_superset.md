# Documentação de Configuração: Container Apache Superset (CT 104)

**Hostname:** `superset`  
**IP (LAN):** `192.168.4.54`  
**URL de Acesso:** `http://superset.gti.local:8088`  
**Finalidade:** Ferramenta de Business Intelligence (BI) para exploração, visualização de dados e criação de dashboards

## 1. Configuração do Container no Proxmox

- **ID:** 104
- **Hostname:** superset
- **Template Base:** `debian-12-template`
- **Recursos:**
  - CPU: 2 Cores
  - RAM: 4 GB
  - Disco: 20 GB

### Configuração de Rede
- **Bridge:** `vmbr0` (Rede Principal/LAN)
- **Tipo:** Estático
- **IP:** `192.168.4.54/24`
- **DNS:** Configurado com IP do servidor DNS local para resolução de domínios `.gti.local`

## 2. Instalação e Configuração

### 2.1. Instalação de Dependências

```bash
apt update
apt install -y build-essential libffi-dev python3-dev python3-pip python3-venv libpq-dev
```

### 2.2. Instalação do Superset

**Criação do ambiente virtual:**
```bash
mkdir -p /opt/superset
python3 -m venv /opt/superset/venv
source /opt/superset/venv/bin/activate
```

**Instalação dos pacotes Python:**
```bash
pip install apache-superset
pip install psycopg2-binary
pip install duckdb "duckdb-engine>=0.9"

# Dependências para correção de erros
pip install "marshmallow<4.0.0" "marshmallow-sqlalchemy<1.0.0" "sqlalchemy-utils<0.39.0"
```

### 2.3. Instalação Manual das Extensões DuckDB

```bash
/opt/superset/venv/bin/python -c "import duckdb; con = duckdb.connect(); con.execute('INSTALL httpfs; LOAD httpfs; INSTALL s3; LOAD s3;')"
```

### 2.4. Configuração do Superset

**Arquivo: `/opt/superset/superset_config.py`**
```python
# Chave secreta (gerar com: openssl rand -base64 42)
SECRET_KEY = '[SUA_CHAVE_SECRETA_GERADA_PELO_OPENSSL]'

# Conexão com PostgreSQL
SQLALCHEMY_DATABASE_URI = 'postgresql+psycopg2://superset:[SUA_SENHA_POSTGRES]@postgres.gti.local/superset'

# Habilita funcionalidades adicionais
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "CSV_UPLOAD": True,
}

# Define diretório de dados
DATA_DIR = '/opt/superset/data'
```

### 2.5. Inicialização da Aplicação

```bash
export FLASK_APP=superset
export SUPERSET_CONFIG_PATH=/opt/superset/superset_config.py
mkdir -p /opt/superset/data

# Executar dentro do venv
superset db upgrade
superset fab create-admin
superset init
```

### 2.6. Configuração do Serviço Systemd

**Arquivo: `/etc/systemd/system/superset.service`**
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

**Ativação do serviço:**
```bash
useradd -r -s /bin/false superset
chown -R superset:superset /opt/superset
systemctl daemon-reload
systemctl enable --now superset.service
```

## 3. Conexão com o Datalake (MinIO via DuckDB)

### Configuração da Conexão DuckDB

1. **Criar Banco de Dados:**
   - **Tipo:** DuckDB
   - **SQLAlchemy URI:** `duckdb:///`

2. **Configuração Avançada (Engine Parameters):**
```json
{
    "connect_args": {
        "config": {
            "s3_endpoint": "minio.gti.local:9000",
            "s3_use_ssl": false,
            "s3_url_style": "path",
            "s3_access_key_id": "[SEU_USUARIO_MINIO]",
            "s3_secret_access_key": "[SUA_SENHA_MINIO]"
        }
    }
}
```

3. **Dataset Virtual:**
```sql
SELECT * FROM 's3://curated-zone/processed_telco_churn.parquet'
```

## 4. Estado Final

- **Acesso Web:** `http://superset.gti.local:8088`
- **Usuário:** `admin`
- **Senha:** [definida durante criação do usuário]

## 5. Problemas Resolvidos

### Problema 1: `ModuleNotFoundError: No module named 'psycopg2'`
- **Solução:** Instalação do `psycopg2-binary`

### Problema 2: `TypeError: Field.__init__() got unexpected keyword argument 'minLength'`
- **Solução:** Instalação de versões específicas dos pacotes marshmallow

### Problema 3: `Permission denied: '/home/superset'`
- **Solução:** Configuração do `DATA_DIR` no `superset_config.py`

### Problema 4: Falha na leitura do Parquet (DuckDB)
- **Solução:** Instalação manual das extensões `httpfs` e `s3`

## 6. Verificação e Monitoramento

### Comandos de Verificação
```bash
# Status do serviço
systemctl status superset.service

# Logs em tempo real
journalctl -u superset.service -f

# Verificar processos
ps aux | grep superset

# Testar conectividade
curl http://localhost:8088
```

### Estrutura do Ambiente
```
/opt/superset/
├── venv/               # Ambiente virtual Python
├── superset_config.py  # Arquivo de configuração
├── data/               # Diretório de dados
└── superset.db         # (Não utilizado - banco em PostgreSQL)
```

## 7. Integração com Outros Serviços

- **PostgreSQL (CT 101):** Armazena metadados e configurações
- **MinIO (CT 102):** Fornece dados da `curated-zone` via DuckDB
- **Airflow (CT 103):** Processa dados que são visualizados no Superset

## 8. Comandos Úteis

### Reiniciar o Serviço
```bash
systemctl restart superset.service
```

### Recarregar Configuração
```bash
systemctl reload superset.service
```

### Verificar Portas em Uso
```bash
netstat -tlnp | grep 8088
```

### Backup da Configuração
```bash
cp /opt/superset/superset_config.py /opt/superset/superset_config.py.backup
```

## 9. Próximos Passos

1. **Criação de Dashboards** para análise de churn
2. **Configuração de Segurança** com roles e permissões
3. **Backup Regular** das configurações e metadados
4. **Otimização de Performance** para grandes volumes de dados

## 10. Status do Container

**Status:** ✅ **CONFIGURADO E OPERACIONAL**

- [x] Serviço systemd ativo e configurado
- [x] Conexão com PostgreSQL estabelecida
- [x] Integração com MinIO via DuckDB funcionando
- [x] Extensões DuckDB instaladas manualmente
- [x] Acesso web disponível
- [x] Configuração de segurança implementada

---

*Documentação atualizada em: 4 de Novembro de 2025*
