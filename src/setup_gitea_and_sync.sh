#!/bin/bash
set -e

# Configurações
GITEA_HOST="http://localhost:3000"
ADMIN_USER="datalake_admin"
ADMIN_PASS="DatalakeAdmin@2026"
ADMIN_EMAIL="admin@datalake.local"
REPO_NAME="datalake-scripts"

echo "=========================================="
echo "🔧 Configurando Gitea Automagicamente..."
echo "=========================================="

# 1. Esperar Gitea estar UP
echo "⏳ Aguardando Gitea iniciar..."
until curl -s $GITEA_HOST > /dev/null; do
    echo "   ... esperando ($GITEA_HOST)"
    sleep 3
done
echo "✅ Gitea está online!"

# 2. Criar Usuário Admin (via CLI dentro do container)
echo "👤 Criando usuário admin..."
docker exec -u git gitea gitea admin user create --username $ADMIN_USER --password $ADMIN_PASS --email $ADMIN_EMAIL --admin || echo "⚠️  Usuário provavelmente já existe."

# 3. Criar Repositório (via API)
echo "📦 Criando repositório '$REPO_NAME'..."
# Obter token é complexo via script simples sem interação, vamos usar CLI também se possível ou Basic Auth
# Gitea CLI create repo is not always available easily, let's use CURL with Basic Auth
RESPONSE=$(curl -X POST "$GITEA_HOST/api/v1/user/repos" \
    -H "content-type: application/json" \
    -u "$ADMIN_USER:$ADMIN_PASS" \
    -d "{\"name\":\"$REPO_NAME\", \"private\": false, \"auto_init\": false}")

echo "   Status criação repo: $?"

# 4. Configurar Git Local e Push
echo "⬆️  Enviando scripts do Spark para o Gitea..."
TARGET_DIR="src" # Diretório local contendo os scripts
# Senha com @ precisa ser encoded ou escapada na URL se possível.
# Como DatalakeAdmin@2026 tem @, vamos escapar para %40
ADMIN_PASS_ENCODED="DatalakeAdmin%402026"
GIT_REMOTE_URL="http://$ADMIN_USER:$ADMIN_PASS_ENCODED@localhost:3000/$ADMIN_USER/$REPO_NAME.git"

if [ -d "$TARGET_DIR" ]; then
    cd $TARGET_DIR
    
    # Inicializa git se não existir
    if [ ! -d ".git" ]; then
        git init
        git checkout -b main
    fi
    
    # Configurar identidade (somente para este repo local se não existir)
    git config user.email "bot@datalake.local"
    git config user.name "DataLake Bot"
    
    # Configura remote
    if git remote | grep "gitea_local"; then
        git remote remove gitea_local
    fi
    git remote add gitea_local $GIT_REMOTE_URL
    
    git add .
    git commit -m "Auto-sync: Scripts Spark e ETL iniciais" || echo "Nada a commitar"
    
    # Push
    git push -u gitea_local main --force
    
    echo "✅ Código sincronizado com sucesso!"
    echo "🔗 Acesse em: $GITEA_HOST/$ADMIN_USER/$REPO_NAME"
else
    echo "❌ Diretório '$TARGET_DIR' não encontrado!"
fi
