# Hive Metastore — Documentação de Implementação (CT `db-hive.gti.local`)

> Documento passo-a-passo para instalar, configurar e integrar o Hive Metastore como repositório de metadados para o Data Lake na plataforma GTI.

---

## ✅ Status Atual - IMPLEMENTADO COM SUCESSO

**Data:** 8 de dezembro de 2025  
**Status:** ✅ **COMPLETO** - Hive Metastore operacional  
**Problemas Resolvidos:**
- ✅ Instalação MariaDB + Hive Metastore
- ✅ Configuração JDBC e conectividade
- ✅ Compatibilidade DataNucleus com MariaDB (MySQLAdapter)
- ✅ Serviço systemd ativo e estável
- ✅ Porta 9083 respondendo corretamente
- ✅ Integração com Spark validada

**Testes Realizados:**
- ✅ Conectividade MariaDB: `SHOW DATABASES;` retorna `metastore`
- ✅ Hive Metastore: Serviço ativo na porta 9083
- ✅ Configuração XML: Sintaxe válida, sem erros de parsing
- ✅ Acesso SSH direto: Restaurado e funcional

---

Índice
- ✅ Status Atual - IMPLEMENTADO COM SUCESSO
- Visão Geral
- Pré-requisitos
- Criação do CT (Proxmox)
- Instalação (MySQL/MariaDB)
- Configuração do Banco de Dados
- Configuração do Hive Metastore
- Integração com Spark
- Segurança e Hardening
- Backup e Replicação
- Monitoramento
- Testes e Validação
- Troubleshooting
- Scripts de Instalação
- Referências

---

## 1. Visão Geral

O Hive Metastore será o repositório central de metadados para tabelas Hive e Iceberg no Data Lake, armazenando esquemas, partições e estatísticas.

Hostname: `db-hive.gti.local` (IP sugerido: `192.168.4.32`)

Banco: MariaDB (compatível com MySQL)

---

## 2. Pré-requisitos
- Container LXC Debian 12
- Usuário `datalake` com sudo
- Volume persistente em `/var/lib/mysql`
- Porta 3306 liberada na rede interna
- Recursos: 2 vCPU, 4-8 GB RAM, 100-200 GB disco

## 2.5 Configuração de Acesso SSH via Chave

Para acesso seguro ao container `db-hive.gti.local`, configure SSH com autenticação por chave Ed25519.

### 2.5.1 Gerar Chave SSH (no host Proxmox/Windows)
```powershell
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\db_hive_admin_id_ed25519 -N "" -C "datalake@db-hive.gti.local"
```

### 2.5.2 Acessar Console do Container (Proxmox)
- No Proxmox, abra o console do CT `db-hive.gti.local`.
- Execute os comandos abaixo para configurar SSH.

### 2.5.3 Instalar e Configurar OpenSSH Server
```bash
apt update && apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
```

### 2.5.4 Configurar SSH para Segurança
Editar `/etc/ssh/sshd_config`:
```bash
nano /etc/ssh/sshd_config
```

Adicionar/modificar:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

Reiniciar SSH:
```bash
systemctl restart ssh
```

### 2.5.5 Configurar Usuário Datalake e Copiar Chave
```bash
adduser --disabled-password --gecos "" datalake
usermod -aG sudo datalake
mkdir -p /etc/sudoers.d
echo 'datalake ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/datalake
chmod 440 /etc/sudoers.d/datalake

su - datalake
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Copie o conteúdo da chave pública (`db_hive_admin_id_ed25519.pub`) para `~/.ssh/authorized_keys`:
```bash
nano ~/.ssh/authorized_keys
# Cole a chave pública aqui
chmod 600 ~/.ssh/authorized_keys
```

### 2.5.6 Configurar /etc/hosts
```bash
nano /etc/hosts
```

Adicionar:
```
192.168.4.32   db-hive.gti.local
192.168.4.32   minio.gti.local
192.168.4.33   spark.gti.local
192.168.4.32   kafka.gti.local
192.168.4.32   trino.gti.local
192.168.4.16   superset.gti.local
192.168.4.32   airflow.gti.local
192.168.4.26   gitea.gti.local
```

### 2.5.7 Testar Acesso SSH
Do host Proxmox/Windows:
```bash
ssh -i $env:USERPROFILE\.ssh\db_hive_admin_id_ed25519 datalake@db-hive.gti.local
```

Se conectar sem senha, a configuração está correta.

### 2.5.8 Automatizando a criação do usuário `datalake` em múltiplos CTs

Disponibilizamos um script para automatizar a criação do usuário `datalake` e a instalação da chave pública:

- `etc/scripts/create-datalake-user.sh <host> [pubkey-path]` — executa localmente: copia a chave para o host e cria/atualiza o usuário e sudoers.
- `etc/scripts/setup_datalake_remote.sh` — helper remoto que é copiado e executado no host para finalizar a configuração.

Exemplo de uso para o host `db-hive.gti.local`:

```bash
# No host local, execute:
# Se você tiver uma chave privada, aponte para ela com o terceiro parâmetro:
bash etc/scripts/create-datalake-user.sh db-hive.gti.local ~/.ssh/db_hive_admin_id_ed25519.pub ~/.ssh/db_hive_admin_id_ed25519

# O script fará:
# 1. scp da chave pública para /tmp/datalake_pubkey no target
# 2. criar o usuário (se necessário)
# 3. adicionar o sudoers (datalake ALL=(ALL) NOPASSWD: ALL)
# 4. criar ~/.ssh, copiar chave para authorized_keys e ajustar permissões
```

O script tentará se conectar via `datalake@host` com a chave para executar a operação; caso não exista o usuário localmente, o script tentará usar `root` via `scp`. Se você preferir usar apenas uma chave privada (sem fornecer explicitamente o arquivo `.pub`), o script tentará gerar a chave pública temporária usando `ssh-keygen`.


---

## 3. Criação do CT (Proxmox)
- Template: Debian 12
- Configuração similar ao MinIO
- Adicionar hosts no `/etc/hosts`

---

## 4. Instalação

### 4.1 Atualizar Sistema
```bash
apt update && apt upgrade -y
apt install -y wget curl vim jq
```

### 4.2 Instalar MariaDB
```bash
apt install -y mariadb-server
systemctl enable --now mariadb
```

### 4.3 Configurar Usuário Datalake
```bash
adduser --disabled-password --gecos "" datalake
usermod -aG sudo datalake
mkdir -p /etc/sudoers.d
echo 'datalake ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/datalake
chmod 440 /etc/sudoers.d/datalake
```

---

## 5. Configuração do Banco de Dados

### 5.1 Secure Installation
```bash
mysql_secure_installation
```

### 5.2 Criar Banco e Usuário
```sql
CREATE DATABASE metastore;
CREATE USER 'hive'@'localhost' IDENTIFIED BY '<SENHA_HIVE_DB>';
GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'localhost';
FLUSH PRIVILEGES;
```

### 5.3 Configuração my.cnf
```ini
[mysqld]
bind-address = 0.0.0.0
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
max_connections = 200
```

---

## 6. Configuração do Hive Metastore

### 6.1 Baixar Hive
```bash
wget https://downloads.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz
tar -xzf apache-hive-3.1.3-bin.tar.gz -C /opt
ln -s /opt/apache-hive-3.1.3-bin /opt/hive
```

### 6.2 Configurar Ambiente
```bash
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
```

### 6.3 hive-site.xml
```xml
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mariadb://localhost:3306/metastore</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.mariadb.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>&lt;SENHA_HIVE_DB&gt; (ou defina a variável HIVE_DB_PASSWORD no .env)</value>
  </property>
</configuration>
```

### 6.3.1 Credenciais e .env (recomendado)

Recomendamos armazenar credenciais sensíveis (usuário/senha do banco) em um arquivo `.env` (ou `hive.env`) fora do repositório e com permissões restritas. Isso evita o commit de segredos e facilita automação.

- Arquivo de exemplo: `/.env.example` no repositório (copie para `.env` e edite as variáveis).
- Local sugerido no servidor: `/etc/hive/hive.env` (leitura por root no momento da instalação).

Exemplo de variáveis usadas:

```properties
HIVE_DB_HOST=localhost
HIVE_DB_PORT=3306
HIVE_DB_NAME=metastore
HIVE_DB_USER=hive
HIVE_DB_PASSWORD=S3cureHivePass2025
HIVE_INIT_SCHEMA=true
HADOOP_HOME=/opt/hadoop
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

Recomendações de segurança:

- Não committe `.env` no repositório; use `.env.example` para referência.
- Proteja o arquivo (`chmod 600 /etc/hive/hive.env`) e restrinja a propriedade para `root:root`.
- Para cenários onde o processo `hive` precise ler o arquivo, ajuste a propriedade e as permissões com cautela (prefira usar ferramentas de secret management em produção).

O script `etc/scripts/configure-hive-metastore.sh` procura automaticamente por `/etc/hive/hive.env`, `etc/scripts/hive.env` (no repositório) e `.env` (no diretório corrente), nessa ordem.

### 6.4 Inicializar Metastore
```bash
schematool -dbType mysql -initSchema
```

### Processo A — Armazenando credenciais em `.env` e executando os scripts

1. No host de desenvolvimento ou máquina local, copie o arquivo de exemplo e edite as variáveis:

```bash
cp .env.example .env
# Edite .env e defina HIVE_DB_PASSWORD e outras variáveis
```

2. Transfira o `.env` para o servidor de produção (recomendado caminho: `/etc/hive/hive.env`):

```bash
scp -i $HOME/.ssh/db_hive_admin_id_ed25519 .env datalake@db-hive.gti.local:/tmp/hive.env
ssh -i $HOME/.ssh/db_hive_admin_id_ed25519 datalake@db-hive.gti.local "sudo mv /tmp/hive.env /etc/hive/hive.env && sudo chown root:root /etc/hive/hive.env && sudo chmod 600 /etc/hive/hive.env"
```

3. Copie os scripts para o servidor e execute-os com `sudo` (os scripts carregam automaticamente `/etc/hive/hive.env` se existir):

```bash
# Copiar scripts para o servidor
scp -i $HOME/.ssh/db_hive_admin_id_ed25519 etc/scripts/install-db-hive.sh datalake@db-hive.gti.local:/tmp/
scp -i $HOME/.ssh/db_hive_admin_id_ed25519 etc/scripts/configure-hive-metastore.sh datalake@db-hive.gti.local:/tmp/

# Movê-los para /opt/scripts e dar permissão
ssh -i $HOME/.ssh/db_hive_admin_id_ed25519 datalake@db-hive.gti.local "sudo mkdir -p /opt/scripts && sudo mv /tmp/install-db-hive.sh /opt/scripts/install-db-hive.sh && sudo mv /tmp/configure-hive-metastore.sh /opt/scripts/configure-hive-metastore.sh && sudo chmod +x /opt/scripts/*.sh"

# Executar scripts
ssh -i $HOME/.ssh/db_hive_admin_id_ed25519 datalake@db-hive.gti.local "sudo /opt/scripts/install-db-hive.sh"
ssh -i $HOME/.ssh/db_hive_admin_id_ed25519 datalake@db-hive.gti.local "sudo /opt/scripts/configure-hive-metastore.sh"
```

4. Valide que o metastore está ativo e ouvindo em 9083:

```bash
ssh -i $HOME/.ssh/db_hive_admin_id_ed25519 datalake@db-hive.gti.local "sudo ss -tnlp | grep 9083"
```

5. (Recomendado) Habilite e configure um serviço systemd para o Hive Metastore, fazendo restart automático e monitoração.


---

## 7. Integração com Spark

Configurações em `spark-defaults.conf`:
```properties
spark.sql.catalogImplementation=hive
spark.hadoop.javax.jdo.option.ConnectionURL=jdbc:mariadb://db-hive.gti.local:3306/metastore
spark.hadoop.javax.jdo.option.ConnectionDriverName=org.mariadb.jdbc.Driver
spark.hadoop.javax.jdo.option.ConnectionUserName=hive
spark.hadoop.javax.jdo.option.ConnectionPassword=${HIVE_DB_PASSWORD}
```

### 7.1 Concessão de Permissões para Spark
Como o Spark roda em um container separado (`spark.gti.local`), é necessário conceder permissões no MariaDB para conexões do host do Spark:
```sql
GRANT ALL PRIVILEGES ON metastore.* TO 'hive'@'spark.gti.local' IDENTIFIED BY 'S3cureHivePass2025';
FLUSH PRIVILEGES;
```

### 7.2 Teste de Integração
Após configurar as permissões, testar a conexão:
```bash
ssh datalake@spark.gti.local
/opt/spark/default/bin/spark-sql --master local --conf spark.sql.catalogImplementation=hive
```
Comando SQL:
```sql
SHOW DATABASES;
```
Saída esperada:
```
default
```

---

## 8. Segurança e Hardening
- Acesso apenas via rede interna
- TLS para conexões (produção)
- Backup regular do banco

---

## 9. Backup e Replicação
- mysqldump para backup
- Replicação MariaDB para HA

---

## 10. Monitoramento
- Logs em `/var/log/mysql/`
- Métricas via Prometheus/MySQL exporter

---

## 11. Testes e Validação
```bash
# Conectar ao banco
mysql -u hive -p metastore

# Verificar tabelas
SHOW TABLES;

# Teste via Spark
spark-sql --master local --conf spark.sql.catalogImplementation=hive
```

---

## 12. Troubleshooting

### 12.1 Problema: Hive Metastore falha ao iniciar com erro de XML parsing
**Sintomas:** `WstxParsingException: Unexpected character combination '</' in epilog`
**Causa:** Arquivo `hive-site.xml` corrompido com conteúdo extra
**Solução:**
```bash
# Recriar o arquivo XML corretamente
sudo tee /opt/apache-hive-3.1.3-bin/conf/hive-site.xml > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:mariadb://localhost:3306/metastore</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionDriverName</name>
    <value>org.mariadb.jdbc.Driver</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionUserName</name>
    <value>hive</value>
  </property>
  <property>
    <name>javax.jdo.option.ConnectionPassword</name>
    <value>S3cureHivePass2025</value>
  </property>
  <property>
    <name>datanucleus.identifierFactory</name>
    <value>datanucleus1</value>
  </property>
  <property>
    <name>datanucleus.rdbms.datastoreAdapterClassName</name>
    <value>org.datanucleus.store.rdbms.adapter.MySQLAdapter</value>
  </property>
  <property>
    <name>hive.metastore.try.direct.sql</name>
    <value>false</value>
  </property>
</configuration>
EOF
```

### 12.2 Problema: Erro SQL syntax com MariaDB
**Sintomas:** `SQLSyntaxErrorException: You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near '"DBS"'`
**Causa:** DataNucleus gerando queries com aspas duplas incompatíveis com MariaDB
**Solução:** 
- Usar `MySQLAdapter` em vez de `MariaDBAdapter`
- Desabilitar `hive.metastore.try.direct.sql`
- Verificar configuração `datanucleus.identifierFactory=datanucleus1`

### 12.3 Problema: Cannot find hadoop installation
**Sintomas:** `$HADOOP_HOME or $HADOOP_PREFIX must be set`
**Causa:** Variáveis de ambiente não definidas
**Solução:** 
```bash
export HADOOP_HOME=/opt/hadoop
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HIVE_HOME=/opt/hive
```

### 12.4 Problema: Acesso SSH direto falha
**Sintomas:** `Permission denied (publickey)`
**Causa:** Chave pública não autorizada no container
**Solução:**
```bash
# No container db-hive
mkdir -p /home/datalake/.ssh
chmod 700 /home/datalake/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdLsgS42YlZFPY8fyKziwPqrSm+NRe+F5NjIWQaoWyN datalake@spark.gti.local" >> /home/datalake/.ssh/authorized_keys
chmod 600 /home/datalake/.ssh/authorized_keys
```

### 12.5 Verificação de Status
```bash
# Status do serviço
systemctl status hive-metastore

# Verificar porta
ss -tlnp | grep 9083

# Testar conectividade MariaDB
mysql -u hive -p -e "SHOW DATABASES;"
```

---

## 13. Scripts de Instalação
- `etc/scripts/install-db-hive.sh`
- `etc/scripts/configure-hive-metastore.sh`

---

## 14. Referências
- `docs/Projeto.md` — Capítulo 4
- Documentação Apache Hive
- `docs/CONTEXT.md`




