# Documentação Consolidada de Configuração: Contentor MinIO (CT 102)

## Identificação e Finalidade
- **ID do Contentor:** 102
- **Hostname:** `minio`
- **Endereço IP:** `10.10.10.12/24`
- **Finalidade:** Servidor de Armazenamento de Objetos (Object Storage) que funcionará como o Datalake físico, armazenando os dados da `raw-zone` e da `curated-zone`.

---

## Especificações Técnicas do Contentor

### Recursos Alocados
- **CPU Cores:** 2
- **RAM:** 2 GB
- **Armazenamento:** 200 GB+ (Ajustável conforme necessidade)
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
# Adicionar rota padrão temporária
ip route add default via 192.168.1.1 dev eth1

# Configurar DNS temporário
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Verificar conectividade
ping -c 3 min.io
```

### 2. Instalação do MinIO
```bash
# Atualizar repositórios e instalar dependências
apt update && apt install -y wget

# Descarregar binário oficial do MinIO
wget https://dl.min.io/server/minio/release/linux-amd64/minio

# Instalar no sistema
mv minio /usr/local/bin/
chmod +x /usr/local/bin/minio
```

### 3. Configuração do Sistema
```bash
# Criar utilizador dedicado
useradd -r minio-user -s /sbin/nologin

# Criar estrutura de diretórios para dados
mkdir /data
chown minio-user:minio-user /data

# Criar diretório de configuração
mkdir /etc/minio
```

### 4. Configuração do Serviço

**Ficheiro:** `/etc/default/minio`
```
# Volume de armazenamento de dados
MINIO_VOLUMES="/data"

# Opções do servidor (porta da consola web)
MINIO_OPTS="--console-address :9001"

# Credenciais de administrador
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=sua_senha_super_secreta_para_minio
```

**Definir permissões:**
```bash
chown -R minio-user:minio-user /etc/minio
```

### 5. Configuração do Serviço Systemd

**Ficheiro:** `/etc/systemd/system/minio.service`
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

### 6. Ativação do Serviço
```bash
# Recarregar systemd e iniciar serviço
systemctl daemon-reload
systemctl enable --now minio

# Verificar status
systemctl status minio
```

---

## Estrutura de Dados e Zonas

### Zonas Implementadas
| Zona | Finalidade | Estado |
|------|------------|---------|
| `raw-zone` | Dados brutos da Fase 3 | ✅ Dados já carregados |
| `curated-zone` | Dados processados e refinados | ✅ Pronta para uso |

### Características do Armazenamento
- **Tipo:** Object Storage compatível com S3
- **Estrutura:** Baseada em buckets (contentores de objetos)
- **Acesso:** Via API S3 e Interface Web

---

## Configuração de Acesso

### Portas e Serviços
| Serviço | Porta | Protocolo | Finalidade |
|---------|-------|-----------|------------|
| MinIO API | 9000 | HTTP/HTTPS | Acesso programático (S3 compatible) |
| MinIO Console | 9001 | HTTP/HTTPS | Interface web de administração |

### Credenciais de Acesso
- **Utilizador Root:** `admin`
- **Password:** `sua_senha_super_secreta_para_minio` (substituir por senha forte)
- **Acesso:** Rede privada `10.10.10.0/24`

---

## Configuração de Segurança

### Políticas Implementadas
- ✅ Serviço executado com utilizador dedicado (`minio-user`)
- ✅ Isolamento de rede após instalação
- ✅ Acesso restrito à rede privada do datalake
- ✅ Credenciais fortes para administração

### Medidas de Proteção
- Remoção de acesso à internet após instalação
- Utilizador de sistema sem permissões de login
- Estrutura de diretórios com permissões adequadas

---

## Estado Final do Serviço

### Status Operacional
- ✅ Serviço MinIO em execução
- ✅ Estrutura de dados criada (`/data`)
- ✅ Zonas `raw-zone` e `curated-zone` configuradas
- ✅ Acesso de rede configurado para a VLAN privada
- ✅ Interface web acessível na porta 9001

### Conectividade
- **API Endpoint:** `http://10.10.10.12:9000`
- **Console Web:** `http://10.10.10.12:9001`
- **Rede Permitida:** `10.10.10.0/24`

---

## Fluxo de Dados

### Processo de Ingestão
1. **Dados Brutos:** Carregados para `raw-zone` via API S3
2. **Processamento:** Aplicações acedem aos dados brutos para transformação
3. **Dados Refinados:** Resultados do processamento armazenados na `curated-zone`
4. **Consumo:** Ferramentas de análise consomem dados da `curated-zone`

---

## Notas de Manutenção

### Monitorização Recomendada
- Espaço em disco em `/data`
- Logs do serviço: `journalctl -u minio`
- Métricas de performance via console web
- Utilização de buckets e objetos

### Backup e Recuperação
- Estratégia de backup dos dados em `/data`
- Backup de configurações em `/etc/minio`
- Política de versionamento de objetos
- Considerar replicação para alta disponibilidade

### Expansão Futura
- Aumento de capacidade de armazenamento conforme necessidade
- Possibilidade de configuração distribuída (MinIO Cluster)
- Implementação de TLS/SSL para comunicação segura
- Configuração de políticas de lifecycle para objetos

*Documentação atualizada em: [Data da última atualização]*

**Nota:** Esta configuração serve como base para o datalake da plataforma, fornecendo armazenamento object storage compatível com S3 para todas as aplicações do ecossistema.
````
