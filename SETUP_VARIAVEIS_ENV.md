# 🔒 Transformação de Credenciais em Variáveis de Ambiente

**Status:** ✅ COMPLETO (08/12/2025)

---

## 📋 O Que Foi Feito

### 1. ✅ Remover Senhas do Código

| Arquivo | Antes | Depois |
|---------|-------|--------|
| `docs/Projeto.md` | `S3cureHivePass2025` | `${HIVE_DB_PASSWORD}` |
| `src/config.py` | ❌ Não existia | ✅ Criado com config centralizada |
| Múltiplos scripts Python | Hardcoded `SparkPass123!` | ⚠️ Ainda precisam ser atualizados |

### 2. ✅ Criar Template de Variáveis

**Arquivo:** `.env.example` (versionado)
- 60+ linhas com comentários explicativos
- Todas as variáveis necessárias documentadas
- Placeholders `<SUA_...>` em vez de senhas reais
- Seções organizadas: Hive, MinIO, Spark, Kafka, etc.

### 3. ✅ Criar Módulo de Configuração Python

**Arquivo:** `src/config.py` (novo)
- Carrega `.env` automaticamente
- Validação de credenciais obrigatórias
- Helper functions: `get_hive_jdbc_url()`, `get_spark_s3_config()`
- Teste integrado: `python -m src.config`

### 4. ✅ Scripts de Carregamento de Variáveis

**PowerShell:** `load_env.ps1`
```powershell
. .\load_env.ps1
```

**Bash/Linux:** `load_env.sh`
```bash
source ./load_env.sh
```

### 5. ✅ Documentação Completa

**Arquivo:** `docs/VARIÁVEIS_ENV.md` (novo - 200+ linhas)
- Setup inicial por SO (Windows, Linux, macOS)
- Como preencher variáveis
- Exemplos de uso em Python, Bash, PowerShell
- Boas práticas e troubleshooting
- Referências para produção (Vault, AWS Secrets)

### 6. ✅ Atualizar .gitignore

**Proteção:**
```
.env                    ← Arquivo com credenciais reais (NÃO versionado)
.env.local
.env.*.local
*.key, *.pem, *.crt     ← Certificados e chaves
```

### 7. ✅ Atualizar CONTEXT.md

**Nova Seção 13:** "🔒 Gestão de Credenciais & Variáveis de Ambiente"
- Estratégia explicada
- Regras críticas
- Links para documentação detalhada

---

## 🚀 Como Usar Agora

### Setup Inicial (Faça uma vez)

#### Windows PowerShell
```powershell
# 1. Copiar template
Copy-Item .env.example .env

# 2. Editar com suas credenciais reais
code .env

# 3. Carregar variáveis (em cada terminal)
. .\load_env.ps1
```

#### Linux/macOS
```bash
# 1. Copiar template
cp .env.example .env

# 2. Editar com suas credenciais
nano .env

# 3. Carregar variáveis
source .env
```

### Usar em Scripts Python

**ANTES (❌ ERRADO):**
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
    .getOrCreate()
```

**DEPOIS (✅ CORRETO):**
```python
from src.config import get_spark_s3_config

spark = SparkSession.builder \
    .config(get_spark_s3_config()) \
    .getOrCreate()
```

### Verificar Configuração

```bash
# Python
python -m src.config

# PowerShell
. .\load_env.ps1
echo "Host: $env:HIVE_DB_HOST"

# Bash
source .env
echo "Host: $HIVE_DB_HOST"
```

---

## 📊 Variáveis Disponíveis

### Hive Metastore
```
HIVE_DB_HOST             = localhost
HIVE_DB_PORT             = 3306
HIVE_DB_NAME             = metastore
HIVE_DB_USER             = hive
HIVE_DB_PASSWORD         = ⚠️ Configure aqui
```

### MinIO / S3A
```
S3A_ACCESS_KEY           = datalake
S3A_SECRET_KEY           = ⚠️ Configure aqui
S3A_ENDPOINT             = http://minio.gti.local:9000
S3A_PATH_STYLE_ACCESS    = true
```

### Spark
```
SPARK_WAREHOUSE_PATH     = s3a://datalake/warehouse
SPARK_S3A_SECRET_KEY     = (mesmo de S3A_SECRET_KEY)
```

### Kafka
```
KAFKA_BROKER             = kafka.gti.local:9092
KAFKA_SECURITY_PROTOCOL  = PLAINTEXT
```

---

## ✅ Verificação

- [x] `.env.example` criado com template completo
- [x] `.env` adicionado a `.gitignore` (segurança)
- [x] `src/config.py` com carregamento automático
- [x] Scripts PowerShell e Bash para carregar variáveis
- [x] Documentação completa em `docs/VARIÁVEIS_ENV.md`
- [x] CONTEXT.md atualizado com nova seção
- [x] Projeto.md com ejemplo de uso (${}format)
- [x] ⚠️ TODO: Atualizar scripts Python individuais para usar `src.config`

---

## 📝 Próximos Passos (TODO)

### [Alta Prioridade]
1. **Atualizar todos os scripts Python** para usar `from src.config import ...`
   - `src/tests/test_*.py` (15+ arquivos)
   - `src/test_iceberg_partitioned.py`
   - Scripts de exemplo

2. **Atualizar scripts shell** para usar `source .env`
   - `etc/scripts/*.sh`
   - `*.sh` na raiz

3. **Criar `.env` no servidor**
   - Via SSH: `scp .env datalake@spark.gti.local:/home/datalake/`
   - Ou criar manualmente: `source /home/datalake/.env`

### [Média Prioridade]
4. **Produção:** Integrar com Vault/AWS Secrets Manager
5. **CI/CD:** Injetar variáveis no pipeline (GitHub Actions, GitLab CI, etc.)
6. **Validação:** Testes para garantir que nenhuma senha seja exposta em logs

### [Opcional]
7. Pre-commit hook para verificar commits de `.env`
8. Script de auditoria para encontrar hardcoded passwords

---

## 🔐 Segurança - Lembretes

✅ Nunca commitar `.env`
✅ Nunca enviar `.env` por email/chat
✅ Nunca fazer push de `.env` para repositório
✅ Sempre usar `source .env` ou script de carregamento
✅ Revisar logs para garantir que senhas não sejam expostas
✅ Rotacionar senhas regularmente

---

**Para detalhes completos, leia:** [`docs/VARIÁVEIS_ENV.md`](docs/VARIÁVEIS_ENV.md)

