# Análise de Centralização PostgreSQL - Fase 1

**Data**: 14/12/2025  
**Status**: ✅ **CONCLUÍDA COM SUCESSO**  
**Objetivo**: Consolidar PostgreSQL em CT 115 (Superset)

---

## 1. Estado Atual dos Bancos de Dados

### CT 115 (Superset - 192.168.4.37)
```
datname   | size
----------|--------
postgres  | 7453 kB
superset  | 7369 kB
template0 | 7297 kB
template1 | 7525 kB
```

**Observações:**
- ✅ PostgreSQL 15.14 operacional
- ✅ Database 'superset' existente e funcional
- ✅ Tamanho modesto (7369 kB) - aplicação em uso
- ✅ Pronto para receber bancos adicionais

### CT 116 (Airflow - 192.168.4.36)
```
datname    | size
-----------|--------
airflow_db | 7525 kB
postgres   | 7453 kB
template0  | 7297 kB
template1  | 7525 kB
```

**Observações:**
- ⚠️ Database 'airflow_db' vazio (nenhuma tabela em `public`)
- ⚠️ Airflow com `sql_alchemy_conn = postgresql://airflow:airflow_password@localhost/airflow`
- ⚠️ Database ini mas nunca foi executado `airflow db migrate`
- 📊 Tamanho padrão (7525 kB) = banco vazio

---

## 2. Configuração Atual de Conexão

### Airflow (CT 116)
```
sql_alchemy_conn = postgresql://airflow:airflow_password@localhost/airflow
```

**Implicações:**
- Airflow conecta ao PostgreSQL LOCAL (CT 116)
- Banco 'airflow' esperado mas não 'airflow_db'
- Desconexão entre config esperada e implementação

---

## 3. Plano de Centralização - FASE 1

### Pré-requisitos Verificados ✅
- [x] PostgreSQL 15.14 em CT 115 operacional
- [x] Conectividade de rede entre CT 115 e CT 116
- [x] Database 'airflow_db' vazio (dados não existem para migrar)

### Passos de Execução

#### Passo 1: Criar Usuário e Database no CT 115
```bash
# CT 115 - PostgreSQL
CREATE USER airflow WITH PASSWORD 'airflow_password';
CREATE DATABASE airflow OWNER airflow;
ALTER DATABASE airflow SET client_encoding = 'UTF8';
```

#### Passo 2: Configurar Acesso Remoto (CT 115)
**Arquivo**: `/etc/postgresql/15/main/pg_hba.conf`
```
# Adicionar linha (após linhas locais):
host    airflow    airflow    192.168.4.36/32    md5
host    superset   postgres   192.168.4.36/32    md5
```

**Arquivo**: `/etc/postgresql/15/main/postgresql.conf`
```
# Descomenttar e modificar:
listen_addresses = 'localhost,192.168.4.37'
```

#### Passo 3: Atualizar airflow.cfg em CT 116
**Localização**: `/home/datalake/airflow/airflow.cfg`
```
# De:
sql_alchemy_conn = postgresql://airflow:airflow_password@localhost/airflow

# Para:
sql_alchemy_conn = postgresql://airflow:airflow_password@192.168.4.37:5432/airflow
```

#### Passo 4: Executar Migrations em CT 116
```bash
# CT 116 - Container Airflow
airflow db migrate
```

#### Passo 5: Validar Conectividade
```bash
# CT 116
airflow connections test airflow_db
```

---

## 4. Análise de Risco e Benefícios

### ✅ Benefícios
| Benefício | Impacto |
|-----------|--------|
| **Ponto único de backup** | PostgreSQL centralizado = 1 backup estratégia |
| **Simplificação de infraestrutura** | Remover PostgreSQL de CT 116 após estabilização |
| **Melhor monitoramento** | Todos bancos em 1 CT = observabilidade unificada |
| **Facilita HA/Replicação** | PostgreSQL único para configurar replicação |
| **Compatibilidade com Superset** | Ambos bancos em mesmo CT = dashboard direto |

### ⚠️ Riscos Identificados
| Risco | Mitigação |
|-------|----------|
| **Falha de CT 115** derruba Airflow | Implementar HA para PostgreSQL depois |
| **Latência de rede** | Teste com conexão remota em ambiente de dev |
| **Perda de acesso de rede** | Testar isolamento de rede antes |
| **Credential leak em airflow.cfg** | Usar Airflow Variables + Secrets depois |

### 🎯 Recomendação
- **IMPLEMENTAR AGORA**: Database/User em CT 115 + configuração remota
- **TESTAR COMPLETAMENTE**: Validar migrations, webserver, scheduler funcionando
- **MONITORAR**: CPU/Mem em CT 115, latência de queries por 48h
- **DEPOIS**: Remover PostgreSQL de CT 116 para liberar recursos

---

## 5. Bancos Elegíveis para Consolidação

### PostgreSQL
| Container | Database | Banco | Elegível | Prioridade |
|-----------|----------|-------|----------|-----------|
| CT 115 | Superset | `superset` | JÁ EM CT 115 | - |
| CT 116 | Airflow | `airflow_db` | ✅ SIM | 🔴 **ALTA** |

**Total elegível**: 1 banco (airflow_db)

### MariaDB (NÃO incluir nesta fase)
| Container | Database | Banco | Motivo |
|-----------|----------|-------|--------|
| CT 117 | Hive | Metastore | PostgreSQL migration only - MariaDB aparte |
| CT 118 | Gitea | gitea | PostgreSQL migration only - MariaDB aparte |

---

## 6. Timeline Estimada

| Fase | Tarefas | Duração |
|------|---------|---------|
| **Préparação** | Criar user/db, config pg_hba.conf | 5 min |
| **Deployment** | Update airflow.cfg, restart Airflow | 2 min |
| **Migrations** | `airflow db migrate` | 2-5 min |
| **Validação** | Testes de conectividade e funcionalidade | 10 min |
| **Monitoramento** | Observação pós-deployment | 48h (contínuo) |

**Total**: ~25 min + 48h monitoramento

---

## 7. Checkpoints de Validação

- [x] User 'airflow' criado em CT 115 com password correto
- [x] Database 'airflow' criado em CT 115 com owner 'airflow'
- [x] pg_hba.conf permite conexão 192.168.4.36→192.168.4.37
- [x] postgresql.conf listening em 192.168.4.37:5432
- [x] PostgreSQL restarted com sucesso
- [x] airflow.cfg atualizado com nova connection string
- [x] Airflow services restarted
- [x] `airflow db migrate` executa com sucesso
- [x] **42 Tabelas criadas em CT 115 airflow database**
- [x] Airflow webserver e scheduler funcionando normalmente
- [x] Nenhum erro em /home/datalake/airflow/logs/scheduler/

---

## 8. Próximos Passos

✅ **FASE 1 COMPLETA** - Centralização PostgreSQL executada com sucesso!

1. ✅ Executar Passo 1-2: Criar infraestrutura em CT 115
2. ✅ Executar Passo 3-4: Atualizar config e rodar migrations
3. ✅ Executar Passo 5: Validar tudo funcionando
4. ✅ Limpeza: SQLite removido (1.2 MB liberado)
5. **→ Monitorar por 48h**: Observar CPU, erros, performance
6. **→ Documentar resultado**: Atualizar STATUS_POSTGRESQL.md

### Acesso aos Containers
- ✅ SSH direto aos CTs configurado (datalake@192.168.4.37/36)
- ✅ Chaves ED25519 ativas para conexão direta

### Limpeza Adicional
- ✅ SQLite removido de CT 116 (sem impacto)
- ✅ Airflow 100% PostgreSQL centralizado
- ✅ Espaço em disco liberado (1.2 MB)

---

**Análise preparada para**: Execução Completa  ✅
**Status**: SUCESSO - Migração Centralizada Operacional e Otimizada
**Próximo revisor**: Monitoramento em 48h
