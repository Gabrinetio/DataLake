# Documentação Consolidada de Configuração: Contentor PostgreSQL (CT 101)

## Identificação e Finalidade
- **ID do Contentor:** 101
- **Hostname:** `postgres`
- **Endereço IP:** `10.10.10.11/24`
- **Finalidade:** Servidor de Base de Dados central para os metadados das aplicações da plataforma (Airflow, Superset, MLflow).

---

## Especificações Técnicas do Contentor

### Recursos Alocados
- **CPU Cores:** 2
- **RAM:** 4 GB
- **Armazenamento:** 40 GB
- **Sistema Base:** Debian 12 (clonado do template `debian-12-template`)

### Configuração de Rede
- **Rede Principal (`net0`):**
  - **Bridge:** `vmbr1` (Rede Privada do Datalake)
  - **Tipo:** Estático
  - **IP:** `10.10.10.11/24`
  - **Gateway:** `10.10.10.1`

- **Rede Temporária (`net1`):**
  - **Status:** Removida após instalação
  - **Bridge:** `vmbr0` (Rede Principal/LAN)
  - **Tipo:** DHCP
  - **Finalidade:** Acesso temporário à internet para instalação de pacotes

---

## Processo de Instalação e Configuração

### 1. Configuração Temporária de Rede para Internet
```bash
# Adicionar rota padrão temporária
ip route add default via 192.168.1.1 dev eth1

# Configurar DNS temporário
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Verificar conectividade
ping -c 3 deb.debian.org
```

### 2. Instalação do PostgreSQL
```bash
# Atualizar repositórios e instalar PostgreSQL
apt update
apt install -y postgresql postgresql-contrib

# Verificar status do serviço
systemctl status postgresql
```

### 3. Criação de Bases de Dados e Utilizadores
```bash
# Aceder à shell do PostgreSQL
su - postgres -c "psql"
```

Comandos SQL executados:
```sql
-- Base de dados para Airflow
CREATE DATABASE airflow;
CREATE USER airflow WITH PASSWORD 'sua_senha_forte_para_airflow';
GRANT ALL PRIVILEGES ON DATABASE airflow TO airflow;

-- Base de dados para Superset
CREATE DATABASE superset;
CREATE USER superset WITH PASSWORD 'sua_senha_forte_para_superset';
GRANT ALL PRIVILEGES ON DATABASE superset TO superset;

-- Base de dados para MLflow
CREATE DATABASE mlflow;
CREATE USER mlflow WITH PASSWORD 'sua_senha_forte_para_mlflow';
GRANT ALL PRIVILEGES ON DATABASE mlflow TO mlflow;
```

### 4. Configuração de Acesso Remoto

**Ficheiro:** `/etc/postgresql/15/main/postgresql.conf`
```ini
# Alterar de:
# listen_addresses = 'localhost'
# Para:
listen_addresses = '*'
```

**Ficheiro:** `/etc/postgresql/15/main/pg_hba.conf**
```
# Adicionar linha:
host    all             all             10.10.10.0/24           md5
```

### 5. Finalização da Configuração
```bash
# Reiniciar serviço para aplicar configurações
systemctl restart postgresql
```

---

## Estrutura de Bases de Dados Criadas

| Aplicação | Base de Dados | Utilizador | Tipo de Acesso |
|-----------|---------------|------------|----------------|
| Apache Airflow | `airflow` | `airflow` | Privilégios totais |
| Apache Superset | `superset` | `superset` | Privilégios totais |
| MLflow | `mlflow` | `mlflow` | Privilégios totais |

---

## Configuração de Segurança

### Políticas de Acesso
- Acesso permitido apenas da rede privada `10.10.10.0/24`
- Autenticação via método `md5` (password)
- Isolamento de rede após instalação (remoção da interface `net1`)

### Medidas Implementadas
- Utilizadores dedicados por aplicação
- Senhas fortes para cada utilizador
- Restrição de acesso por rede
- Remoção de acesso à internet após instalação

---

## Estado Final do Serviço

### Status Operacional
- ✅ Serviço PostgreSQL em execução
- ✅ Bases de dados criadas e configuradas
- ✅ Acesso de rede configurado para a VLAN privada
- ✅ Isolamento de rede implementado
- ✅ Pronto para receber conexões das aplicações

### Conectividade
- **Porta:** 5432 (PostgreSQL padrão)
- **Rede Permitida:** `10.10.10.0/24`
- **Método de Autenticação:** Password (md5)

---

## Notas de Manutenção

### Backup Recomendado
As bases de dados contêm metadados críticos das aplicações. Recomenda-se:
- Backup regular das bases `airflow`, `superset` e `mlflow`
- Política de retenção de backups adequada
- Teste periódico de restauro

### Monitorização
- Verificar logs em `/var/log/postgresql/`
- Monitorizar utilização de recursos (CPU, RAM, disco)
- Acompanhar conexões ativas e performance

*Documentação atualizada em: [Data da última atualização]*
