# Gestão de Credenciais e Variáveis de Ambiente

## 🔒 Segurança - IMPORTANTE

**NUNCA commitar credenciais reais no repositório!**

O arquivo `.env` está listado em `.gitignore` para evitar commit acidental de senhas.

---

## 📋 Estrutura

```
projeto/
├── .env.example          ← Template (VERSIONADO - sem senhas reais)
├── .env                  ← Arquivo local (NÃO versionado - com senhas reais)
├── load_env.ps1          ← Script PowerShell para carregar variáveis
├── src/
│   ├── config.py         ← Configuração centralizada (Python)
│   └── tests/            ← Testes usam config.py
└── docs/
    └── VARIÁVEIS_ENV.md  ← Este arquivo
```

---

## 🚀 Como Usar

### 1. Setup Inicial

#### Windows (PowerShell)

```powershell
# Copiar template
Copy-Item .env.example .env

# Editar com suas credenciais
code .env

# Carregar variáveis no terminal
. .\load_env.ps1
```

#### Linux/macOS (Bash/Zsh)

```bash
# Copiar template
cp .env.example .env

# Editar com suas credenciais
nano .env

# Carregar variáveis
source .env
```

### 2. Preencher Variáveis

Edite `.env` e substitua os placeholders:

```dotenv
# ANTES (template)
HIVE_DB_PASSWORD=<SUA_SENHA_HIVE_AQUI>
S3A_SECRET_KEY=<SUA_SENHA_S3A_AQUI>

# DEPOIS (seu arquivo)
HIVE_DB_PASSWORD=minha_senha_secreta_123
S3A_SECRET_KEY=outra_senha_456
```

### 3. Usar em Scripts Python

```python
# ✅ CORRETO - Usar config.py
from src.config import HIVE_DB_PASSWORD, S3A_SECRET_KEY, get_spark_s3_config

spark_config = get_spark_s3_config()

# ❌ ERRADO - Hardcoded
HIVE_DB_PASSWORD = "S3cureHivePass2025"  # NÃO FAÇA ISTO!
```

### 4. Usar em Scripts Shell

```bash
#!/bin/bash
source .env

# Usar as variáveis
mysql -u $HIVE_DB_USER -p$HIVE_DB_PASSWORD -h $HIVE_DB_HOST

# Ou com ssh
ssh datalake@spark.gti.local "HIVE_DB_PASSWORD=$HIVE_DB_PASSWORD /scripts/deploy.sh"
```

### 5. Usar em PowerShell

```powershell
. .\load_env.ps1

# Variáveis agora acessíveis
Write-Host "Host: $env:HIVE_DB_HOST"
Write-Host "User: $env:HIVE_DB_USER"
```

---

## 📋 Variáveis Disponíveis

### Hive Metastore
```
HIVE_DB_HOST              = localhost
HIVE_DB_PORT              = 3306
HIVE_DB_NAME              = metastore
HIVE_DB_USER              = hive
HIVE_DB_PASSWORD          = ⚠️ CONFIGURE COM SUAS CREDENCIAIS
```

### MinIO / S3A
```
S3A_ACCESS_KEY            = datalake
S3A_SECRET_KEY            = ⚠️ CONFIGURE COM SUAS CREDENCIAIS
S3A_ENDPOINT              = http://minio.gti.local:9000
S3A_PATH_STYLE_ACCESS     = true
```

### Spark
```
SPARK_WAREHOUSE_PATH      = s3a://datalake/warehouse
SPARK_S3A_SECRET_KEY      = (mesmo de S3A_SECRET_KEY)
```

### Kafka
```
KAFKA_BROKER              = kafka.gti.local:9092
KAFKA_SECURITY_PROTOCOL   = PLAINTEXT
```

---

## 🔍 Verificação

### Python
```bash
python -m src.config
```

Saída esperada:
```
✅ Todas as configurações estão válidas
   - Hive: hive@localhost:3306/metastore
   - S3A: datalake@http://minio.gti.local:9000
   - Warehouse: s3a://datalake/warehouse
```

### PowerShell
```powershell
. .\load_env.ps1
echo "Hive: $env:HIVE_DB_HOST"
```

### Bash
```bash
source .env
echo "Hive: $HIVE_DB_HOST"
```

---

## 🚨 Troubleshooting

### Erro: "Variáveis de ambiente obrigatórias não configuradas"

**Solução:** Edite `.env` e preencha todos os placeholders `<SUA_...>`:

```bash
# Verificar quais estão faltando
grep "<SUA_" .env
```

### Erro: "Permission denied" ao executar script

**Linux/macOS:**
```bash
chmod +x load_env.ps1
. ./load_env.ps1
```

**PowerShell:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
. .\load_env.ps1
```

### Variável não persiste após fechar terminal

**Esperado!** Cada terminal tem seu próprio contexto. Para persistir:

- **Linux/macOS:** Adicione ao `~/.bashrc` ou `~/.zshrc`:
  ```bash
  export HIVE_DB_HOST=localhost
  export HIVE_DB_PASSWORD="sua_senha"
  # ... etc
  ```

- **Windows (Permanente):** Use "Edit environment variables" do sistema:
  - Painel de Controle → Sistema → Variáveis de Ambiente
  - Criar variáveis do sistema/usuário

- **Windows (Sessão):** Execute `load_env.ps1` a cada terminal

---

## 📝 Boas Práticas

### ✅ Faça

- ✅ Copie `.env.example` para `.env` localmente
- ✅ Use `.env` apenas localmente (não versionado)
- ✅ Carregue variáveis com `source .env` ou `. load_env.ps1`
- ✅ Use `os.getenv()` em Python para acessar variáveis
- ✅ Valide variáveis obrigatórias no startup
- ✅ Use secrets management em produção (Vault, AWS Secrets Manager)

### ❌ Não Faça

- ❌ Commitar `.env` com senhas reais
- ❌ Hardcoding de senhas em scripts
- ❌ Usar credenciais em URLs (ex: `mysql://user:pass@host`)
- ❌ Compartilhar `.env` por chat/email
- ❌ Deixar senhas em histórico de terminal
- ❌ Usar credenciais em logs/prints

---

## 🔐 Produção

Para ambientes de produção, use um gerenciador de secrets:

### Opções
1. **HashiCorp Vault** - Gerenciamento centralizado
2. **AWS Secrets Manager** - Para infraestrutura AWS
3. **Google Cloud Secret Manager** - Para GCP
4. **Azure Key Vault** - Para Azure
5. **Kubernetes Secrets** - Se usar containers
6. **systemd environment files** - Para serviços Linux

### Exemplo com Vault
```python
import hvac

client = hvac.Client(url='http://vault.example.com:8200')
secrets = client.secrets.kv.read_secret_version(path='datalake')
password = secrets['data']['data']['HIVE_DB_PASSWORD']
```

---

## 📞 Referências

- [dotenv-python](https://github.com/theskumar/python-dotenv)
- [Environment Variables Best Practices](https://12factor.net/config)
- [HashiCorp Vault](https://www.vaultproject.io/)

