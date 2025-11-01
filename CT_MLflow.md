# Documentação de Configuração: Container MLflow (CT 105)

**Hostname:** `mlflow`  
**IP Privado:** `10.10.10.15`  
**Finalidade:** Plataforma de MLOps para tracking de experimentos e registro de modelos.

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 105
* **Hostname:** mlflow
* **Recursos:** 2 Cores, 2GB RAM, 20GB Disco
* **Rede Principal (`net0`):** Bridge `vmbr1`, IP Estático `10.10.10.15/24`
* **Rede Temporária (`net1`):** Bridge `vmbr0`, DHCP (removida após a instalação)

---

## 2. Passos de Instalação e Configuração (Executados como `root`)

### 2.1. Habilitação Temporária de Acesso à Internet

```bash
# Configurar rota padrão temporária
ip route add default via [IP_DO_GATEWAY_DA_LAN] dev eth1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2.2. Pré-requisito: Criação do Bucket no MinIO

Antes da instalação, foi necessário criar um bucket chamado `mlflow` no serviço MinIO (CT 102) para servir como *Artifact Store*.

**Passos realizados:**
1. Acessar a interface do MinIO em `http://minio.lan`
2. Fazer login com credenciais de administrador
3. Criar um novo bucket chamado `mlflow`

### 2.3. Instalação de Dependências de Sistema

```bash
apt update
apt install -y build-essential libpq-dev python3-venv python3-pip
```

### 2.4. Instalação do MLflow

O MLflow e os seus conectores foram instalados via `pip` dentro de um ambiente virtual isolado em `/opt/mlflow/venv`.

```bash
# Criação do ambiente
mkdir -p /opt/mlflow
python3 -m venv /opt/mlflow/venv
source /opt/mlflow/venv/bin/activate

# Instalação dos pacotes
pip install mlflow psycopg2-binary boto3
```

### 2.5. Serviço `systemd`

Foi criado um serviço `systemd` em `/etc/systemd/system/mlflow.service` para gerenciar o MLflow Tracking Server.

**Conteúdo do arquivo de serviço:**
```ini
[Unit]
Description=MLflow Tracking Server
After=network.target postgresql.service minio.service

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/mlflow

# Variáveis de ambiente para a conexão com o MinIO (S3)
Environment="AWS_ACCESS_KEY_ID=admin"
Environment="AWS_SECRET_ACCESS_KEY=sua_senha_super_secreta_para_minio"
Environment="MLFLOW_S3_ENDPOINT_URL=http://10.10.10.12:9000"

# Comando de execução do servidor MLflow
ExecStart=/opt/mlflow/venv/bin/mlflow server \
    --backend-store-uri postgresql+psycopg2://mlflow:sua_senha_forte_para_mlflow@10.10.10.11/mlflow \
    --default-artifact-root s3://mlflow/ \
    --host 0.0.0.0

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Ativação do Serviço:**
```bash
systemctl daemon-reload
systemctl enable --now mlflow.service
```

### 2.6. Finalização

A interface de rede temporária (`net1`) foi removida na UI do Proxmox após a conclusão da instalação.

---

## 3. Configuração do Gateway

### Proxy Host no Nginx Proxy Manager

* **Domain Names:** `mlflow.lan`
* **Forward Hostname / IP:** `10.10.10.15`
* **Forward Port:** `5000`

### Configuração de DNS Local

Adicione a seguinte linha ao arquivo `hosts` da máquina cliente:
```
192.168.1.106   mlflow.lan
```

---

## 4. Estado Final

O container `mlflow` (CT 105) está totalmente operacional. O serviço está configurado para usar:

* **PostgreSQL** como *Backend Store* (metadados dos experimentos)
* **MinIO** como *Artifact Store* (modelos, métricas, arquivos)

O acesso à interface web é feito através do Reverse Proxy (Gateway) no endereço **`http://mlflow.lan`**.

---

## 5. Verificação e Monitoramento

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
- **URL:** `http://mlflow.lan`
- **Porta:** `5000` (configurada automaticamente pelo proxy)

### Estrutura de Diretórios

```
/opt/mlflow/
├── venv/                   # Ambiente virtual Python
└── (logs do serviço systemd)
```

---

## 6. Arquitetura de Armazenamento

### Backend Store (PostgreSQL)
- **Função:** Armazena metadados dos experimentos (nomes, parâmetros, métricas, tags)
- **Conexão:** `postgresql+psycopg2://mlflow:sua_senha@10.10.10.11/mlflow`

### Artifact Store (MinIO/S3)
- **Função:** Armazena artefatos (modelos treinados, gráficos, arquivos de dados)
- **Bucket:** `mlflow`
- **Endpoint:** `http://10.10.10.12:9000`

---

## 7. Próximos Passos

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
mlflow.set_tracking_uri("http://mlflow.lan")

# Iniciar um experimento
with mlflow.start_run():
    mlflow.log_param("param1", 5)
    mlflow.log_metric("accuracy", 0.85)
    
    # Registrar um modelo
    mlflow.sklearn.log_model(model, "model")
```

---

## 8. Solução de Problemas

### Verificar Conexão com PostgreSQL
```bash
# Dentro do ambiente virtual
python -c "
import psycopg2
conn = psycopg2.connect('postgresql://mlflow:sua_senha@10.10.10.11/mlflow')
print('Conexão com PostgreSQL: OK')
"
```

### Verificar Conexão com MinIO
```bash
# Dentro do ambiente virtual
python -c "
import boto3
s3 = boto3.client(
    's3',
    endpoint_url='http://10.10.10.12:9000',
    aws_access_key_id='admin',
    aws_secret_access_key='sua_senha'
)
buckets = s3.list_buckets()
print('Conexão com MinIO: OK')
print('Buckets:', [b['Name'] for b in buckets['Buckets']])
"
```

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O MLflow está funcionando corretamente e acessível via `http://mlflow.lan`.
