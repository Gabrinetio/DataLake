# Documentação de Configuração: Container MLflow (CT 105)

**Hostname:** `mlflow`  
**IP (LAN):** `192.168.4.55`  
**URL de Acesso:** `http://mlflow.gti.local:5000`  
**Finalidade:** Plataforma de MLOps para tracking de experimentos e registro de modelos de Machine Learning

## 1. Configuração do Container no Proxmox

- **ID:** 105
- **Hostname:** mlflow
- **Template Base:** `debian-12-template`
- **Recursos:**
  - CPU: 2 Cores
  - RAM: 2 GB
  - Disco: 20 GB

### Configuração de Rede
- **Bridge:** `vmbr0` (Rede Principal/LAN)
- **IP:** `192.168.4.55/24`
- **DNS:** Configurado com IP do servidor DNS local para resolução de domínios `.gti.local`

## 2. Instalação e Configuração

### 2.1. Pré-requisito: Bucket no MinIO

Antes da instalação, foi criado um bucket chamado **`mlflow`** no MinIO através da interface web (`http://minio.gti.local:9001`).

### 2.2. Instalação de Dependências

```bash
apt update
apt install -y build-essential libpq-dev python3-venv python3-pip
```

### 2.3. Instalação do MLflow

**Criação do ambiente virtual:**
```bash
mkdir -p /opt/mlflow
python3 -m venv /opt/mlflow/venv
source /opt/mlflow/venv/bin/activate
```

**Instalação dos pacotes Python:**
```bash
pip install mlflow psycopg2-binary
pip install "boto3==1.33.13"
```

### 2.4. Configuração do Serviço Systemd

**Arquivo: `/etc/systemd/system/mlflow.service`**
```ini
[Unit]
Description=MLflow Tracking Server (Final Corrected)
After=network.target

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/mlflow

# Variáveis Críticas (Fix Boto3 Endpoint)
Environment="AWS_ACCESS_KEY_ID=admin"
Environment="AWS_SECRET_ACCESS_KEY=iRB;g2&ChZ&XQEW!"

# Fixes de Protocolo S3 (para Boto3/MinIO)
Environment="AWS_S3_ADDRESSING_STYLE=path"
Environment="AWS_S3_SECURE=false"
Environment="AWS_REGION=us-east-1"
Environment="AWS_REQUEST_CHECKSUM_CALCULATION=when_required"
Environment="AWS_RESPONSE_CHECKSUM_VALIDATION=when_required"

# Fix Definitivo (Usar variável Boto3 nativa)
Environment="AWS_ENDPOINT_URL=http://192.168.4.52:9000"
Environment="MLFLOW_S3_ENDPOINT_URL=http://192.168.4.52:9000"

# Comando de execução
ExecStart=/opt/mlflow/venv/bin/mlflow server \
    --backend-store-uri 'postgresql+psycopg2://mlflow:iRB;g2&ChZ&XQEW!@postgres.gti.local/mlflow' \
    --default-artifact-root "s3://mlflow/" \
    --host 0.0.0.0 \
    --port 5000 \
    --workers 4 \
    --allowed-hosts "mlflow.gti.local,mlflow.gti.local:5000"

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Ativação do serviço:**
```bash
systemctl daemon-reload
systemctl enable --now mlflow.service
```

## 3. Estado Final

O container MLflow está totalmente operacional com a seguinte configuração:

- **Backend Store (Metadados):** PostgreSQL (CT 101)
- **Artifact Store (Modelos):** MinIO (CT 102), bucket `mlflow`
- **Acesso Web:** `http://mlflow.gti.local:5000`

## 4. Problemas Resolvidos

### Problema 1: `NoSuchBucket` ao executar `mlflow.log_model()`
- **Causa:** Versão antiga do `boto3==1.33.13` no Airflow (CT 103) ignorava variáveis de ambiente
- **Solução:** Implementação de "Monkey Patch" na DAG do Airflow

### Problema 2: `Rejected request with invalid Host header`
- **Causa:** Validação de segurança do `Host header`
- **Solução:** Adição da flag `--allowed-hosts` no serviço systemd

### Problema 3: `could not translate host name "postgres.gti.local"`
- **Causa:** Container não configurado para usar DNS local
- **Solução:** Configuração do DNS Server nas Options do container LXC

## 5. Verificação e Monitoramento

### Comandos de Verificação
```bash
# Status do serviço
systemctl status mlflow.service

# Logs em tempo real
journalctl -u mlflow.service -f

# Verificar processos
ps aux | grep mlflow

# Testar conectividade
curl http://localhost:5000
```

### Estrutura do Ambiente
```
/opt/mlflow/
├── venv/           # Ambiente virtual Python
└── mlruns/         # (Não utilizado - artifacts no MinIO)
```

## 6. Configurações de Armazenamento

### Backend Store (PostgreSQL)
- **URI:** `postgresql+psycopg2://mlflow:sua_senha@postgres.gti.local/mlflow`
- **Armazena:** Metadados de experimentos, runs e modelos

### Artifact Store (MinIO)
- **URI:** `s3://mlflow/`
- **Armazena:** Modelos treinados, arquivos, métricas

## 7. Integração com Outros Serviços

- **Airflow (CT 103):** Executa DAGs de treinamento que registram modelos no MLflow
- **PostgreSQL (CT 101):** Armazena metadados dos experimentos
- **MinIO (CT 102):** Armazena artifacts dos modelos

## 8. Comandos Úteis

### Reiniciar o Serviço
```bash
systemctl restart mlflow.service
```

### Verificar Portas em Uso
```bash
netstat -tlnp | grep 5000
```

### Testar Conexão com PostgreSQL
```bash
/opt/mlflow/venv/bin/python -c "
import psycopg2
conn = psycopg2.connect(
    host='postgres.gti.local',
    database='mlflow',
    user='mlflow',
    password='iRB;g2&ChZ&XQEW!'
)
print('Conexão PostgreSQL: OK')
conn.close()
"
```

## 9. Status do Container

**Status:** ✅ **CONFIGURADO E OPERACIONAL**

- [x] Serviço systemd ativo e configurado
- [x] Conexão com PostgreSQL estabelecida
- [x] Integração com MinIO funcionando
- [x] Acesso web disponível
- [x] Configuração de segurança implementada
- [x] Compatibilidade com Boto3 resolvida

---

*Documentação atualizada em: 4 de Novembro de 2025*
