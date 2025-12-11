#!/bin/bash
# ========================================
# load_env.sh - Carregar variáveis de ambiente
# ========================================
#
# USO:
#   source ./load_env.sh  (em bash/zsh)
#
# Ou para executar em subshell:
#   bash ./load_env.sh script.sh arg1 arg2
#

ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Arquivo $ENV_FILE não encontrado!"
    echo "   1. Copie de .env.example: cp .env.example .env"
    echo "   2. Edite com suas credenciais reais"
    echo "   3. Execute novamente"
    exit 1
fi

echo "🔄 Carregando variáveis de ambiente de: $ENV_FILE"

# Carregar variáveis (ignorar comentários e linhas vazias)
count=0
while IFS= read -r line || [ -n "$line" ]; do
    # Remover espaços em branco
    line=$(echo "$line" | xargs)
    
    # Ignorar linhas vazias e comentários
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    
    # Exportar variável
    export "$line"
    var_name=$(echo "$line" | cut -d= -f1)
    echo "  ✅ $var_name"
    ((count++))
done < "$ENV_FILE"

echo ""
echo "✅ $count variáveis carregadas com sucesso!"
echo ""
echo "Variáveis principais carregadas:"
echo "  - HIVE_DB_HOST: ${HIVE_DB_HOST:-não configurado}"
echo "  - S3A_ENDPOINT: ${S3A_ENDPOINT:-não configurado}"
echo "  - SPARK_WAREHOUSE_PATH: ${SPARK_WAREHOUSE_PATH:-não configurado}"
