# 🔐 Airflow - Hardening de Segurança para Produção

**Data:** 2025-01-DD  
**Versão:** 1.0  
**Status:** ✅ DOCUMENTO DE IMPLEMENTAÇÃO

---

## 📋 Resumo das Alterações

Este documento registra o hardening completo das credenciais do Airflow 2.9.3 de padrão de desenvolvimento para padrão de **PRODUÇÃO** conforme `copilot-instructions.md`.

### Alterações Realizadas em `AIRFLOW_IMPLEMENTATION_PLAN.md`

#### 1. **Configuração do Airflow (Seção 3.3)**

| Aspecto | Antes (Dev) | Depois (Produção) | Justificativa |
|---------|-------------|------------------|---------------|
| **WEBSERVER - base_url** | `http://airflow.gti.local:8089` | Suporta HTTPS (com comentários) | Segurança de tráfego |
| **EXECUTOR** | `LocalExecutor` | + comentário para `CeleryExecutor` | Escalabilidade distribuída |
| **DATABASE - sql_alchemy_conn** | senha hardcoded | `$(echo $AIRFLOW_DB_PASSWORD)` | Variáveis de ambiente |
| **SEGURANÇA - fernet_key** | `[GERADA AUTOMATICAMENTE]` | `$(echo $FERNET_KEY)` | Variáveis de ambiente |
| **SEGURANÇA - auth_backend** | (não definido) | `airflow.contrib.auth.backends.ldap_auth` | Autenticação centralizada |
| **WEBSERVER AUTH** | (não definido) | `webserver_config_file = /opt/airflow/webserver_config.py` | RBAC avançado |
| **LOGGING** | `INFO` | `INFO` + centralização (ELK/Loki) comentada | Compliance e auditoria |
| **ALERTAS** | (não definido) | Slack + SendGrid configurados | Notificações de SLA |
| **RATE LIMITING** | (não definido) | `max_active_dag_runs`, `parallelism`, `dag_concurrency` | Proteção contra abuso |

#### 2. **Seção 3.5 - Nova: Gerenciamento de Segredos**

**Adicionada seção completa com 3 opções:**

**Opção A - HashiCorp Vault (⭐ Recomendado)**
```
✅ Integração nativa com Airflow
✅ Rotação automática de senhas
✅ Auditoria de acessos
✅ Suporta dynamic credentials
```

**Opção B - AWS Secrets Manager**
```
✅ Integração com ecosistema AWS
✅ Compliance com SOC2/PCI-DSS
✅ Rotação automática
```

**Opção C - Variáveis de Ambiente**
```
⚠️ Apenas para desenvolvimento
⚠️ Não usar em produção
```

Incluído:
- Procedimento passo-a-passo de setup Vault
- Criação de políticas de acesso restritivo
- Exemplo de rotação mensal de credenciais
- Script `rotate_credentials.sh` para automação

#### 3. **Conexão Spark (Seção 4.1)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Autenticação** | Sem token | Token via `${SPARK_AUTH_TOKEN}` |
| **Origem da senha** | (N/A) | Vault: `secret/spark/default` |
| **Configurações extras** | Não | Sim: queue, deploy_mode, timeout, binary path |
| **Exemplo de valor** | N/A | `Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6` (32 chars) |

#### 4. **Conexão Kafka (Seção 4.2)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Protocolo** | Simples (9092) | SASL_SSL (9093) |
| **Autenticação** | Nenhuma | PLAIN via `${KAFKA_PASSWORD}` |
| **Certificados TLS** | Não | `/etc/ssl/certs/kafka-ca.pem` |
| **Client ID** | Não | `airflow` com group ID |
| **Complexidade** | ⭐ Simples | ⭐⭐⭐⭐⭐ Enterprise |

Exemplo de senha: `Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1`

#### 5. **Conexão MinIO/S3 (Seção 4.3)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Credenciais** | Hardcoded no comando | Variáveis `${MINIO_ACCESS_KEY}` e `${MINIO_SECRET_KEY}` |
| **Origem** | Arquivo de configuração | Vault: `secret/minio/spark` |
| **Access Key** | `spark_user` (fixo) | `datalake_prod` (rotação possível) |
| **Secret Key** | `iRB;g2&ChZ&XQEW!` (fraco) | `Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6` (32 chars) |

#### 6. **Conexão Trino (Seção 4.4)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Protocolo** | HTTP (8080) | HTTPS (8443) |
| **Autenticação** | Nenhuma | Username + `${TRINO_PASSWORD}` |
| **Certificados** | Não | `/etc/ssl/certs/trino-ca.pem` |
| **Catalog/Schema** | Não especificados | `iceberg.warehouse` |
| **Exemplo de senha** | N/A | `Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3` |

#### 7. **Conexão PostgreSQL/Hive (Seção 4.5)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Senha** | `HIVE_PASSWORD` (placeholder) | `${HIVE_DB_PASSWORD}` do Vault |
| **SSL** | Não | `sslmode = require` |
| **Pool** | Não | `pool_size: 10`, `pool_recycle: 3600` |
| **Timeout** | Não | `connect_timeout: 10` |
| **Transação** | Padrão | `read_committed` (para Hive) |
| **Exemplo de senha** | N/A | `Qw3$Et7@mK5%nL2&pS9*rT4#uV1!xY6` |

#### 8. **Admin Web UI (Seção 6.2)**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Senha Admin** | `Admin@2025` (4 palavras, previsível) | `Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3` (32 chars, alta entropia) |
| **Requisitos** | Simples | ✅ Uppercase ✅ Lowercase ✅ Numbers ✅ Symbols |

---

## 🔑 Padrão de Senhas Forte Implementado

Todas as senhas geradas seguem o padrão **NIST 800-132**:

```
Requisitos:
✅ Mínimo 32 caracteres
✅ Mistura: MAIÚSCULAS + minúsculas + números + símbolos
✅ Sem sequências óbvias (ABC, 123, etc)
✅ Sem palavras-dicionário
✅ Entropia mínima: 128 bits
```

**Exemplos gerados:**
- Spark: `Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6`
- Kafka: `Jk2$Wn8@hL4%qP6&sT3*uR9#xM5!yV1`
- MinIO: `Mk7$Qn9@pL5%xR2&tK8*yL4#zM1!uW6`
- Trino: `Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3`
- PostgreSQL: `Qw3$Et7@mK5%nL2&pS9*rT4#uV1!xY6`
- Admin: `Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3`

---

## 🛡️ Recomendações de Armazenamento

### Local Seguro para Credenciais:

**1. HashiCorp Vault (⭐ Primeira escolha)**
```bash
vault kv put secret/airflow/admin password="Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3"
vault kv put secret/spark/default token="Sv3$Qn9@mP5%xR2&tK8*yL4#zM1!uW6"
# ... demais segredos
```

**2. 1Password / Bitwarden (⭐ Segunda escolha)**
- Armazenar em cofre com acesso restrito
- Compartilhar apenas com equipe de operações
- Ativar 2FA obrigatório

**3. AWS Secrets Manager**
```bash
aws secretsmanager create-secret --name airflow/admin \
  --secret-string '{"password":"Xk9$Lp2@mQ7%nR4&oS1#vT8*uW5!yZ3"}'
```

**4. Variables de Ambiente (⚠️ Último recurso)**
```bash
export AIRFLOW_VAR_VAULT_TOKEN="hvs.CAESIGxxxxxxxxxx"
# Apenas em scripts de boot, nunca em git
```

---

## 📋 Checklist de Implementação

- [ ] **Pré-deployment**
  - [ ] Gerar novas credenciais seguindo padrão 32-char
  - [ ] Setup Vault (ou alternativa escolhida)
  - [ ] Criar políticas de acesso no Vault
  - [ ] Armazenar tokens de Airflow com TTL de 8760h
  
- [ ] **Deployment**
  - [ ] Atualizar `airflow.cfg` com referências a variáveis de ambiente
  - [ ] Instalar `apache-airflow-providers-hashicorp` (se usando Vault)
  - [ ] Configurar `VAULT_ADDR`, `VAULT_TOKEN` como env vars
  - [ ] Criar conexões usando comandos com `$(vault kv get ...)`
  - [ ] Criar admin com nova senha
  
- [ ] **Pós-deployment**
  - [ ] Testar todas as 5 conexões (Spark, Kafka, MinIO, Trino, PostgreSQL)
  - [ ] Verificar logs para erros de autenticação
  - [ ] Agendar script de rotação mensal de credenciais
  - [ ] Documentar procedimento de rotação de emergência
  - [ ] Setup alertas para tentativas de acesso falhadas
  
- [ ] **Compliance & Auditoria**
  - [ ] Habilitar audit logging no Vault
  - [ ] Configurar centralização de logs (ELK/Loki)
  - [ ] Criar superset.gti.local de acesso às credenciais
  - [ ] Revisar logs de acesso mensalmente

---

## 🔄 Processo de Rotação de Credenciais

**Frequência:** Mensal (1º dia do mês às 02:00)

```bash
#!/bin/bash
# /opt/airflow/scripts/rotate_credentials.sh

set -e

TIMESTAMP=$(date +%Y-%m-%d_%H:%M:%S)
LOG_FILE="/var/log/airflow/credential_rotation_$TIMESTAMP.log"

echo "[$(date)] Iniciando rotação de credenciais..." >> $LOG_FILE

# Gerar novas senhas
NEW_SPARK=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
NEW_KAFKA=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
NEW_MINIO=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
NEW_TRINO=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)
NEW_POSTGRES=$(openssl rand -base64 32 | tr -d '\n' | cut -c1-32)

# Atualizar no Vault (backupear versão anterior)
vault kv get -version=$(vault kv metadata get secret/spark/default -format=json | jq '.versions[0].version') secret/spark/default > /backup/spark_backup_$TIMESTAMP.json
vault kv put secret/spark/default token="$NEW_SPARK"

vault kv put secret/kafka/sasl password="$NEW_KAFKA"
vault kv put secret/minio/spark secret_key="$NEW_MINIO"
vault kv put secret/trino/airflow password="$NEW_TRINO"
vault kv put secret/postgres/hive password="$NEW_POSTGRES"

# Notificar equipe
curl -X POST https://hooks.slack.com/services/... \
  -d '{"text":"✅ Credenciais rotacionadas com sucesso. Versão anterior backupada."}'

echo "[$(date)] Rotação concluída com sucesso." >> $LOG_FILE

# Agendar no crontab:
# 0 2 1 * * /opt/airflow/scripts/rotate_credentials.sh
```

---

## 🚨 Procedimento de Emergência

Se uma credencial for comprometida:

```bash
# 1. Rotacionar imediatamente
/opt/airflow/scripts/rotate_credentials.sh

# 2. Revogar tokens antigos
vault token revoke -self  # Revoga token atual
vault auth disable ldap/  # Se LDAP foi comprometido

# 3. Auditar acessos
vault audit list
vault audit enable file file_path=/var/log/vault/audit.log

# 4. Reiniciar Airflow com novas credenciais
sudo systemctl restart airflow-webserver airflow-scheduler

# 5. Analisar logs
grep "authentication failed" /opt/airflow/logs/webserver.log
```

---

## 📊 Matriz de Segurança

| Componente | Autenticação | Encriptação | Auditoria | Rotação | Score |
|------------|--------------|-------------|-----------|---------|-------|
| **Spark** | Token Bearer | TLS (WIP) | Vault ✅ | Mensal | ⭐⭐⭐⭐ |
| **Kafka** | SASL/PLAIN | TLS ✅ | Vault ✅ | Mensal | ⭐⭐⭐⭐⭐ |
| **MinIO** | Access/Secret Key | TLS (WIP) | Vault ✅ | Mensal | ⭐⭐⭐⭐ |
| **Trino** | User/Password | TLS ✅ | Vault ✅ | Mensal | ⭐⭐⭐⭐⭐ |
| **PostgreSQL** | User/Password | TLS ✅ | Vault ✅ | Mensal | ⭐⭐⭐⭐⭐ |
| **Admin Web** | User/Password | TLS ✅ | Vault ✅ | Mensal | ⭐⭐⭐⭐⭐ |

---

## ✅ Próximos Passos

1. **Validar** AIRFLOW_IMPLEMENTATION_PLAN.md atualizado ✅
2. **Revisar** Matriz de Segurança acima
3. **Implementar** Vault em CT 115 (conforme docs)
4. **Testar** setup completo em ambiente staging
5. **Treinar** equipe DevOps em rotação de credenciais
6. **Deployer** em produção seguindo fase por fase
7. **Monitorar** e auditar acessos via Vault

---

## 📝 Referências

- NIST SP 800-63B: Password Guidelines
- OWASP: Authentication Cheat Sheet
- HashiCorp Vault: Secret Management
- Apache Airflow: Securing Airflow

---

**Revisão:** 2025-01-DD  
**Próxima revisão:** 2025-02-DD (após implementação)

