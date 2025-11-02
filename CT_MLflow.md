# Documentação de Configuração: Container MLflow (CT 105) - Versão Final

**Hostname:** `mlflow`  
**IP (LAN):** `192.168.4.55`  
**URL de Acesso:** `http://mlflow.gti.local`  
**Finalidade:** Plataforma de MLOps para tracking de experimentos e registro de modelos de Machine Learning.

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 105
* **Hostname:** mlflow
* **Recursos:** 2 Cores, 2GB RAM, 20GB Disco
* **Template Base:** `debian-12-template`
* **Rede (`net0`):**
  * **Bridge:** `vmbr0` (Rede Principal/LAN)
  * **Tipo:** Estático
  * **Endereço IP:** `192.168.4.55/24`
  * **Gateway:** O gateway da sua rede local (ex: `192.168.4.1`)
* **DNS (em Options):** Configurado com o IP do seu servidor DNS local para resolver os domínios `.gti.local`

---

## 2. Passos de Instalação e Configuração

### 2.1. Pré-requisito: Criação do Bucket no MinIO

Antes da instalação, foi necessário acessar à interface do MinIO (via `http://minio.gti.local`) e criar um bucket chamado **`mlflow`**.

### 2.2. Instalação de Dependências de Sistema

```bash
apt update
apt install -y build-essential libpq-dev python3-venv python3-pip
```

### 2.3. Instalação do MLflow

O MLflow e os seus conectores foram instalados via `pip` dentro de um ambiente virtual isolado.

```bash
# Criação do ambiente
mkdir -p /opt/mlflow
python3 -m venv /opt/mlflow/venv
source /opt/mlflow/venv/bin/activate

# Instalação dos pacotes Python necessários
pip install mlflow psycopg2-binary boto3
```

### 2.4. Serviço `systemd`

Foi criado um serviço `systemd` em `/etc/systemd/system/mlflow.service` para gerenciar o MLflow Tracking Server, utilizando o servidor padrão (FastAPI/uvicorn) que respeita as configurações de segurança.

**Conteúdo final do arquivo de serviço:**

```ini
[Unit]
Description=MLflow Tracking Server (Final Corrected)
After=network.target

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/mlflow

# Variáveis de ambiente para a conexão com MinIO (S3)
Environment="AWS_ACCESS_KEY_ID=admin"
Environment="AWS_SECRET_ACCESS_KEY=sua_senha_super_secreta_para_minio"
Environment="MLFLOW_S3_ENDPOINT_URL=http://minio.gti.local:9000"

# Comando de execução do servidor MLflow com a flag de segurança correta
ExecStart=/opt/mlflow/venv/bin/mlflow server \
    --backend-store-uri 'postgresql+psycopg2://mlflow:sua_senha_forte_para_mlflow@postgres.gti.local/mlflow' \
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

*Nota: A string de conexão com o PostgreSQL foi colocada entre aspas simples (`'`) para evitar que caracteres especiais na senha (como `!`) sejam interpretados pelo terminal.*

**Ativação do Serviço:**

```bash
systemctl daemon-reload
systemctl enable --now mlflow.service
```

---

## 3. Estado Final

O container `mlflow` (CT 105) está totalmente operacional, com o serviço executando de forma estável e acessível diretamente na rede local através do seu nome de domínio.

* **Backend Store:** PostgreSQL em `postgres.gti.local`
* **Artifact Store:** MinIO em `minio.gti.local`
* **Acesso Web:** `http://mlflow.gti.local`

---

## 4. Verificação e Monitoramento

### Comandos Úteis

**Verificar status do serviço:**
```bash
systemctl status mlflow.service
```

**Ver logs em tempo real:**
```bash
journalctl -u mlflow.service -f
```

**Reiniciar o serviço:**
```bash
systemctl restart mlflow.service
```

**Testar se a aplicação está respondendo:**
```bash
curl -I http://localhost:5000
```

### Acesso à Interface Web

A interface web do MLflow está disponível através de:
- **URL:** `http://mlflow.gti.local`
- **Porta:** `5000` (configurada automaticamente)

### Estrutura de Diretórios

```
/opt/mlflow/
├── venv/                   # Ambiente virtual Python
└── (logs do serviço systemd)
```

---

## 5. Arquitetura de Armazenamento

### Backend Store (PostgreSQL)
- **Função:** Armazena metadados dos experimentos (nomes, parâmetros, métricas, tags)
- **Conexão:** `postgresql+psycopg2://mlflow:sua_senha@postgres.gti.local/mlflow`

### Artifact Store (MinIO/S3)
- **Função:** Armazena artefatos (modelos treinados, gráficos, arquivos de dados)
- **Bucket:** `mlflow`
- **Endpoint:** `http://minio.gti.local:9000`

---

## 6. Próximos Passos

1. **Configurar Experimentos:** Criar e organizar experimentos de machine learning
2. **Integração com Código:** Instrumentar scripts de treinamento com MLflow
3. **Registro de Modelos:** Configurar registro e versionamento de modelos
4. **Implantação:** Configurar implantação de modelos para produção
5. **Backup:** Configurar backup regular dos metadados e artefatos

### Exemplo de Uso Básico

```python
import mlflow
import mlflow.sklearn

# Configurar o tracking server
mlflow.set_tracking_uri("http://mlflow.gti.local")

# Iniciar um experimento
with mlflow.start_run():
    mlflow.log_param("param1", 5)
    mlflow.log_metric("accuracy", 0.85)
    
    # Registrar um modelo
    mlflow.sklearn.log_model(model, "model")
```

---

## 7. Problemas Resolvidos Durante a Configuração

Durante a configuração, foram diagnosticados e resolvidos vários problemas complexos:

### Erro 1: `could not translate host name "postgres.gti.local" to address`

* **Causa:** O container do MLflow não estava configurado para usar o servidor DNS local, portanto não conseguia resolver os endereços `.gti.local`
* **Solução:** Configurar o **DNS Server** nas **Options** do container LXC no Proxmox, apontando para o IP do DNS local

### Erro 2: `Rejected request with invalid Host header`

* **Causa Raiz:** A validação de segurança do MLflow é uma comparação de texto exata. O `header` `Host` enviado pelo navegador era `mlflow.gti.local:5000` (incluindo a porta), mas a configuração inicial apenas permitia `mlflow.gti.local`
* **Solução:** Modificar a flag de inicialização no serviço `systemd` para permitir explicitamente o domínio com e sem a porta: `--allowed-hosts "mlflow.gti.local,mlflow.gti.local:5000"`

### Desafio 3: Configurações de Segurança Ignoradas

* **Causa:** Tentativas iniciais de usar o `gunicorn` diretamente (`ExecStart=/.../gunicorn ...`) faziam com que as configurações de segurança do MLflow (como `--allowed-hosts` ou a variável de ambiente correspondente) fossem ignoradas, pois esse `middleware` de segurança só funciona com o servidor padrão do MLflow (FastAPI/uvicorn)
* **Solução:** Reverter para o uso do comando `mlflow server`, garantindo que o servidor correto é utilizado

---

## 8. Configurações de Segurança Adicional

Para ambientes de produção, considere adicionar as seguintes configurações:

```ini
# No arquivo de serviço systemd, adicione:
Environment="MLFLOW_AUTH_ENABLED=true"
Environment="MLFLOW_AUTH_USERS=admin:password123,user:userpass"
```

### Configuração de Backup Automatizado

```bash
# Script de backup para metadados do MLflow
#!/bin/bash
pg_dump -h postgres.gti.local -U mlflow mlflow > /backup/mlflow_$(date +%Y%m%d).sql

# Backup dos artefatos do MinIO
mc mirror minio/mlflow /backup/mlflow_artifacts_$(date +%Y%m%d)/
```

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O MLflow está funcionando corretamente e acessível via `http://mlflow.gti.local`.
