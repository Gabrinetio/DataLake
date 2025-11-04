# Documentação Consolidada de Configuração: Contêiner MinIO (CT 102)

## Identificação e Finalidade
- **ID do Contêiner:** 102
- **Hostname:** `minio`
- **Endereço IP:** `10.10.10.12/24`
- **Finalidade:** Servidor de Armazenamento de Objetos (Object Storage) que funcionará como o Datalake físico, armazenando os dados da `raw-zone` e da `curated-zone`.

---

## Especificações Técnicas do Contêiner

### Recursos Alocados
- **CPU Cores:** 2
- **RAM:** 2 GB
- **Armazenamento:** 200 GB+ (ajustável conforme necessidade)
- **Sistema Base:** Debian 12 (clonado do template `debian-12-template`)

### Configuração de Rede
- **Rede Principal (`net0`):**
  - **Bridge:** `vmbr1` (Rede Privada do Datalake)
  - **Tipo:** Estático
  - **IP:** `10.10.10.12/24`
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
# Configurar rota padrão temporária para acesso externo
ip route add default via 192.168.1.1 dev eth1

# Configurar DNS para resolução de nomes
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 2. Instalação do MinIO (Método Binário)

**Por que usar o binário?** O MinIO é distribuído como um único executável auto-contido, oferecendo:
- Instalação simplificada sem dependências complexas
- Fácil atualização (substituição de apenas um arquivo)
- Controle total sobre a versão instalada

```bash
# Preparar o sistema e instalar ferramentas necessárias
apt update && apt install -y wget

# Baixar o binário oficial mais recente do MinIO
wget https://dl.min.io/server/minio/release/linux-amd64/minio

# Instalar no PATH do sistema para acesso global
mv minio /usr/local/bin/

# Tornar o arquivo executável
chmod +x /usr/local/bin/minio
```

### 3. Configuração de Segurança e Estrutura

**Princípio de Segurança:** Executar serviços com privilégios mínimos necessários

```bash
# Criar usuário de sistema dedicado (sem permissão de login)
useradd -r minio-user -s /sbin/nologin

# Criar diretório principal para armazenamento de objetos
mkdir /data

# Definir propriedade para o usuário do serviço
chown minio-user:minio-user /data
```

### 4. Configuração do Serviço

**Arquivo de Configuração:** `/etc/default/minio`
```
# Volume de armazenamento principal
MINIO_VOLUMES=\"/data\"

# Opções do servidor (ativa console web na porta 9001)
MINIO_OPTS=\"--console-address :9001\"

# Credenciais de administração - SUBSTITUA POR UMA SENHA FORTE
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=sua_senha_super_secreta_para_minio
```

**Aplicar Permissões de Segurança:**
```bash
# Criar diretório de configuração
mkdir /etc/minio

# Garantir que o usuário do serviço tenha acesso às configurações
chown -R minio-user:minio-user /etc/minio
```

### 5. Configuração do Serviço Systemd

**Arquivo:** `/etc/systemd/system/minio.service`
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

### 6. Ativação e Verificação do Serviço
```bash
# Recarregar definições de serviço do systemd
systemctl daemon-reload

# Ativar inicialização automática e iniciar serviço
systemctl enable --now minio

# Verificar status do serviço
systemctl status minio
```

---

## Arquitetura de Dados do Datalake

### Zonas de Dados Implementadas
| Zona | Finalidade | Estado | Descrição |
|------|------------|--------|-----------|
| `raw-zone` | Dados brutos | ✅ **Dados carregados** | Dados em sua forma original, sem processamento |
| `curated-zone` | Dados processados | ✅ **Pronta para uso** | Dados refinados, limpos e preparados para análise |

### Características do Object Storage
- **Compatibilidade:** API S3 completa
- **Persistência:** Dados armazenados em `/data`
- **Estrutura:** Organização por buckets e objetos
- **Acesso:** Dual (API + Interface Web)

---

## Configuração de Acesso e Conectividade

### Endpoints de Serviço
| Tipo | Endpoint | Porta | Finalidade |
|------|----------|-------|------------|
| **API S3** | `http://10.10.10.12:9000` | 9000 | Acesso programático e integração |
| **Console Web** | `http://10.10.10.12:9001` | 9001 | Interface gráfica de administração |

### Credenciais de Acesso
- **Usuário Administrador:** `admin`
- **Senha:** `sua_senha_super_secreta_para_minio` (*substitua por uma senha forte*)
- **Âmbito de Acesso:** Rede privada `10.10.10.0/24`

---

## Modelo de Segurança Implementado

### Princípios Aplicados
- ✅ **Privilégio Mínimo:** Serviço executado como usuário dedicado
- ✅ **Isolamento de Rede:** Acesso apenas na VLAN privada do datalake
- ✅ **Segurança das Credenciais:** Configuração separada em arquivo de ambiente
- ✅ **Proteção de Dados:** Permissões adequadas nos diretórios

### Medidas Específicas
- Usuário de sistema sem shell de login
- Remoção do acesso à internet após instalação
- Configuração isolada em `/etc/minio`
- Dados armazenados com propriedade adequada

---

## Estado Final do Serviço

### Status Operacional
- ✅ Serviço MinIO ativo e em execução
- ✅ Estrutura de armazenamento (`/data`) configurada
- ✅ Zonas de dados criadas e operacionais
- ✅ Acesso de rede restrito à VLAN privada
- ✅ Mecanismos de autenticação configurados

### Conectividade e Acesso
- **Rede Autorizada:** `10.10.10.0/24`
- **Protocolos:** HTTP (possibilidade futura de HTTPS)
- **Autenticação:** Credenciais via MINIO_ROOT_USER/PASSWORD

---

## Fluxo de Dados do Datalake

### Pipeline de Processamento
1. **Ingestão:** Dados brutos carregados para a `raw-zone` via API S3
2. **Processamento:** Aplicações processam dados da raw-zone
3. **Refino:** Dados transformados armazenados na `curated-zone`
4. **Consumo:** Ferramentas analíticas consomem dados da curated-zone

### Integrações Previstas
- Apache Airflow (orquestração de pipelines)
- Apache Superset (visualização e análise)
- MLflow (experimentos de machine learning)
- Aplicações customizadas (via API S3)

---

## Operação e Manutenção

### Monitoramento Recomendado
- **Espaço em Disco:** Utilização de `/data`
- **Logs do Serviço:** `journalctl -u minio`
- **Performance:** Métricas via console web (9001)
- **Utilização:** Estatísticas de buckets e objetos

### Estratégias de Backup
- Backup regular dos dados em `/data`
- Backup das configurações em `/etc/minio`
- Versionamento de objetos críticos
- Políticas de retenção e lifecycle

### Expansão Futura
- **Capacidade:** Aumento de armazenamento conforme necessário
- **Disponibilidade:** Configuração em cluster distribuído
- **Segurança:** Implementação de TLS/SSL
- **Funcionalidades:** Políticas de lifecycle automático

*Documentação atualizada em: [Data da última atualização]*

**Nota Técnica:** Esta configuração estabelece a base do datalake corporativo, fornecendo storage object compatível com S3 para todo o ecossistema de dados da plataforma.
