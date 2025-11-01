# Documentação de Configuração: Container MLflow (CT 105)

**Hostname:** `mlflow`  
**IP Privado:** `10.10.10.15`  
**Finalidade:** Plataforma de MLOps para tracking de experimentos e registro de modelos de Machine Learning.

---

## 1. Configuração do Container (CT) no Proxmox

* **ID:** 105
* **Hostname:** mlflow
* **Recursos:** 2 Cores, 2GB RAM, 20GB Disco
* **Rede:** `10.10.10.15/24` em `vmbr1`
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

### 2.2. Pré-requisito: Criação do Bucket no MinIO

Antes da instalação, foi necessário acessar à interface do MinIO (via `http://minio.lan`) e criar um bucket chamado **`mlflow`**. Este bucket servirá como *Artifact Store*, o local onde o MLflow armazenará os arquivos dos modelos, gráficos, e outros artefatos.

### 2.3. Instalação de Dependências de Sistema

```bash
# Executado como root no CT 105
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

# Instalação dos pacotes Python necessários
pip install mlflow psycopg2-binary boto3
```

### 2.5. Serviço `systemd`

Foi criado um serviço `systemd` em `/etc/systemd/system/mlflow.service` para gerenciar o MLflow Tracking Server. A configuração final reflete a solução para o erro `Invalid Host header`.

**Conteúdo do arquivo de serviço:**
```ini
[Unit]
Description=MLflow Tracking Server
After=network.target

[Service]
User=root
Group=root
Type=simple
WorkingDirectory=/opt/mlflow

# Variáveis de ambiente para a conexão com o MinIO (S3)
Environment="AWS_ACCESS_KEY_ID=admin"
Environment="AWS_SECRET_ACCESS_KEY=sua_senha_super_secreta_para_minio"
Environment="MLFLOW_S3_ENDPOINT_URL=http://10.10.10.12:9000"

# A SOLUÇÃO FINAL: Adiciona o domínio de acesso à lista de hosts permitidos do MLflow
Environment="MLFLOW_SERVER_ALLOWED_HOSTS=mlflow.lan, localhost, 127.0.0.1, 10.10.10.106"

# Comando de execução do servidor MLflow
ExecStart=/opt/mlflow/venv/bin/mlflow server \
    --backend-store-uri postgresql+psycopg2://mlflow:sua_senha_forte_para_mlflow@10.10.10.11/mlflow \
    --default-artifact-root s3://mlflow/ \
    --host 0.0.0.0 \
    --port 5000 \
    --workers 4

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

*Nota 1: A senha do PostgreSQL deve ser codificada para URL se contiver caracteres especiais.*
*Nota 2: A variável de ambiente `MLFLOW_SERVER_ALLOWED_HOSTS` foi a solução definitiva para o erro `Invalid Host header`, instruindo diretamente a aplicação MLflow a confiar no nosso nome de domínio local. Tentativas de usar `--gunicorn-opts` ou de manipular os cabeçalhos no proxy não foram suficientes, pois a camada de segurança da própria aplicação MLflow precisava desta permissão explícita.*

**Ativação do Serviço:**
```bash
systemctl daemon-reload
systemctl enable --now mlflow.service
```

### 2.6. Finalização

A interface de rede temporária (`net1`) foi removida na UI do Proxmox após a conclusão da instalação.

---

## 3. Configuração do Reverse Proxy (Gateway)

Para que o acesso via `http://mlflow.lan` funcione, foi criada uma regra no Nginx Proxy Manager (CT 106).

1.  **Acesso à UI de Admin:** A interface de gerenciamento do NPM está disponível em `http://192.168.4.106:81`.

2.  **Criação do Proxy Host:** Foi criado um `Proxy Host` com as seguintes especificações:

    * **Aba `Details`:**
        * **Domain Names:** `mlflow.lan`
        * **Scheme:** `http`
        * **Forward Hostname / IP:** `10.10.10.15`
        * **Forward Port:** `5000`
    * **Aba `Advanced`:** Para garantir que todos os cabeçalhos necessários são passados corretamente para o serviço de backend, o seguinte snippet de configuração foi adicionado:
      ```nginx
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      ```

3.  **Configuração de DNS Local:** No computador cliente, o arquivo `hosts` foi editado para mapear o domínio ao IP do gateway:

    ```
    192.168.4.106   mlflow.lan
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

## 7. Problemas Resolvidos

### Erro: `Invalid Host header`
**Solução:** Adição da variável de ambiente `MLFLOW_SERVER_ALLOWED_HOSTS` no serviço systemd, incluindo o domínio `mlflow.lan`

### Erro de Conexão com PostgreSQL
**Solução:** Verificação da string de conexão e codificação adequada da senha

### Erro de Conexão com MinIO
**Solução:** Configuração correta das credenciais AWS e endpoint URL

---

## 8. Próximos Passos

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

**Status:** ✅ **CONFIGURADO E OPERACIONAL** - O MLflow está funcionando corretamente e acessível via `http://mlflow.lan`.
