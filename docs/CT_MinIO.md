# Documentação de Configuração: Container MinIO (CT 102)

**Hostname:** `minio`  
**IP (LAN):** `192.168.4.52`  
**URL de Acesso:** `http://minio.gti.local`  
**Finalidade:** Servidor de Armazenamento de Objetos (Object Storage) funcionando como Datalake físico

## 1. Configuração do Container no Proxmox

- **ID:** 102
- **Hostname:** minio
- **Template Base:** `debian-12-template`
- **Recursos:**
  - CPU: 2 Cores
  - RAM: 2 GB
  - Disco: 200 GB+

### Configuração de Rede
- **Bridge:** `vmbr0` (Rede Principal/LAN)
- **Tipo:** Estático
- **IP:** `192.168.4.52/24`
- **DNS:** Configurado com IP do servidor DNS local para resolução de domínios `.gti.local`

## 2. Instalação e Configuração

### 2.1. Instalação do MinIO

```bash
# Atualizar sistema e instalar dependências
apt update && apt install -y wget

# Baixar binário do MinIO
wget https://dl.min.io/server/minio/release/linux-amd64/minio

# Instalar no sistema
mv minio /usr/local/bin/
chmod +x /usr/local/bin/minio
```

### 2.2. Configuração de Segurança

```bash
# Criar usuário dedicado
useradd -r minio-user -s /sbin/nologin

# Criar diretório de armazenamento
mkdir /data
chown minio-user:minio-user /data
```

### 2.3. Configuração do Serviço

**Arquivo: `/etc/default/minio`**
```
# Volume de armazenamento principal
MINIO_VOLUMES="/data"

# Opções do servidor
MINIO_OPTS="--console-address :9001"

# Credenciais de administração
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=[SUA_SENHA_FORTE_PARA_MINIO]
```

**Aplicar permissões:**
```bash
mkdir -p /etc/minio
chown -R minio-user:minio-user /etc/minio
```

### 2.4. Configuração do Serviço Systemd

**Arquivo: `/etc/systemd/system/minio.service`**
```ini
[Unit]
Description=MinIO
Wants=network-online.target
After=network-online.target

[Service]
User=minio-user
Group=minio-user
EnvironmentFile=/etc/default/minio
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

[Install]
WantedBy=multi-user.target
```

### 2.5. Ativação do Serviço

```bash
systemctl daemon-reload
systemctl enable --now minio
systemctl status minio
```

## 3. Arquitetura de Dados do Datalake

### Zonas de Dados Implementadas

| Zona | Finalidade | Estado | Descrição |
|------|------------|--------|-----------|
| `raw-zone` | Dados brutos | ✅ **Pronta** | Dados em sua forma original, sem processamento |
| `curated-zone` | Dados processados | ✅ **Pronta** | Dados refinados, limpos e preparados para análise |
| `mlflow` | Artefatos de ML | ✅ **Pronta** | Armazena modelos e artefatos do MLflow |

## 4. Configuração de Acesso

### Endpoints de Serviço

| Tipo | Endpoint (DNS) | Porta | Finalidade |
|------|----------------|-------|------------|
| **API S3** | `http://minio.gti.local:9000` | 9000 | Acesso programático e integração |
| **Console Web** | `http://minio.gti.local:9001` | 9001 | Interface gráfica de administração |

### Credenciais de Acesso
- **Usuário Administrador:** `admin`
- **Senha:** `[SUA_SENHA_FORTE_PARA_MINIO]`
- **Âmbito de Acesso:** Rede local `192.168.4.0/24`

## 5. Modelo de Segurança

### Princípios Aplicados
- ✅ **Privilégio Mínimo:** Serviço executado como usuário dedicado `minio-user`
- ✅ **Isolamento de Rede:** Acesso apenas pela rede local
- ✅ **Segurança das Credenciais:** Configuração separada em arquivo de ambiente
- ✅ **Proteção de Dados:** Permissões adequadas nos diretórios

## 6. Estado Final do Serviço

### Status Operacional
- ✅ Serviço MinIO ativo e em execução
- ✅ Estrutura de armazenamento (`/data`) configurada
- ✅ Zonas de dados criadas e operacionais
- ✅ Acesso de rede restrito à LAN
- ✅ Mecanismos de autenticação configurados

### Conectividade e Acesso
- **Rede Autorizada:** `192.168.4.0/24`
- **Protocolos:** HTTP
- **Autenticação:** Credenciais via MINIO_ROOT_USER/PASSWORD

## 7. Fluxo de Dados do Datalake

### Pipeline de Processamento
1. **Ingestão:** Dados brutos carregados para a `raw-zone` (DAG de ETL do Airflow)
2. **Processamento:** Aplicações processam dados da `raw-zone`
3. **Refino:** Dados transformados armazenados na `curated-zone`
4. **Consumo:** Ferramentas analíticas (Superset) e ML (MLflow) consomem dados

### Integrações
- **Apache Airflow:** Orquestração de pipelines
- **Apache Superset:** Visualização e análise
- **MLflow:** Experimentos de machine learning

## 8. Verificação e Monitoramento

### Comandos de Verificação
```bash
# Status do serviço
systemctl status minio

# Logs em tempo real
journalctl -u minio -f

# Verificar espaço em disco
df -h /data

# Testar conectividade
curl http://localhost:9001
```

### Estrutura do Ambiente
```
/
├── data/                    # Armazenamento de objetos
│   ├── raw-zone/           # Dados brutos
│   ├── curated-zone/       # Dados processados
│   └── mlflow/             # Artefatos de ML
├── etc/
│   ├── default/
│   │   └── minio           # Configurações do serviço
│   └── minio/              # Configurações adicionais
└── usr/local/bin/minio     # Binário do MinIO
```

## 9. Operação e Manutenção

### Monitoramento Recomendado
- **Espaço em Disco:** Utilização de `/data`
- **Logs do Serviço:** `journalctl -u minio -f`
- **Performance:** Métricas via console web (`:9001`)

### Estratégias de Backup
- Backup regular dos dados em `/data`
- Backup das configurações em `/etc/minio`

### Comandos de Manutenção
```bash
# Reiniciar serviço
systemctl restart minio

# Verificar espaço utilizado
du -sh /data/*

# Limpar logs antigos
journalctl --vacuum-time=7d
```

## 10. Integração com Outros Serviços

### Airflow (CT 103)
- **Conexão S3:** `minio_s3_default`
- **Uso:** Upload/download de dados para processamento

### Superset (CT 104)
- **Conexão DuckDB:** Leitura direta de arquivos Parquet
- **Uso:** Visualização de dados da curated-zone

### MLflow (CT 105)
- **Artifact Store:** `s3://mlflow/`
- **Uso:** Armazenamento de modelos e artefatos

## 11. Status do Container

**Status:** ✅ **CONFIGURADO E OPERACIONAL**

- [x] Serviço systemd ativo e configurado
- [x] Estrutura de armazenamento preparada
- [x] Zonas de dados criadas e funcionais
- [x] Segurança e permissões implementadas
- [x] Integração com outros serviços testada
- [x] Acesso web disponível

---

*Documentação atualizada em: 4 de Novembro de 2025*
