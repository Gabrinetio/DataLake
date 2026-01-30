#!/bin/bash
# =============================================================================
# DATALAKE FB - Script de Configuração Completa
# =============================================================================
# Este script configura automaticamente todos os componentes da stack após
# o primeiro `docker compose up -d`.
#
# Uso:
#   ./configure_stack.sh
#
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "🔧 DATALAKE FB - Configuração Automática"
echo "=========================================="
echo ""

# -----------------------------------------------------------------------------
# 1. GITEA - Ativar Install Lock e Criar Usuário Admin
# -----------------------------------------------------------------------------
configure_gitea() {
    echo "1️⃣  Configurando Gitea..."
    
    # Aguardar Gitea estar pronto
    echo "   ⏳ Aguardando Gitea iniciar..."
    until curl -s http://localhost:3000 > /dev/null 2>&1; do
        sleep 3
    done
    
    # Ativar INSTALL_LOCK se necessário
    INSTALL_LOCK=$(docker exec gitea grep "INSTALL_LOCK" /data/gitea/conf/app.ini 2>/dev/null | grep -c "true" || echo "0")
    if [ "$INSTALL_LOCK" == "0" ]; then
        echo "   🔒 Ativando Install Lock..."
        docker exec gitea sed -i 's/INSTALL_LOCK = false/INSTALL_LOCK = true/' /data/gitea/conf/app.ini
        docker restart gitea
        sleep 5
    fi
    
    # Criar usuário admin
    echo "   👤 Criando usuário admin..."
    docker exec -u git gitea gitea admin user create \
        --config /data/gitea/conf/app.ini \
        --username datalake_admin \
        --password DatalakeAdmin@2026 \
        --email admin@datalake.local \
        --admin 2>/dev/null || echo "   ⚠️  Usuário já existe"
    
    echo "   ✅ Gitea configurado!"
    echo "      URL: http://localhost:3000"
    echo "      User: datalake_admin"
    echo "      Pass: DatalakeAdmin@2026"
}

# -----------------------------------------------------------------------------
# 2. SUPERSET - Copiar Scripts de RBAC
# -----------------------------------------------------------------------------
configure_superset() {
    echo ""
    echo "2️⃣  Configurando Superset..."
    
    # Aguardar Superset estar pronto
    echo "   ⏳ Aguardando Superset iniciar..."
    until docker exec datalake-superset ls /app 2>/dev/null; do
        sleep 5
    done
    
    # Copiar scripts de RBAC
    echo "   📄 Copiando scripts de configuração..."
    docker cp "$PROJECT_ROOT/src/setup_superset_roles.py" datalake-superset:/app/ 2>/dev/null || true
    docker cp "$PROJECT_ROOT/src/setup_superset_assets.py" datalake-superset:/app/ 2>/dev/null || true
    
    # Verificar
    if docker exec datalake-superset ls /app/setup_superset_roles.py /app/setup_superset_assets.py > /dev/null 2>&1; then
        echo "   ✅ Scripts copiados!"
    else
        echo "   ⚠️  Scripts não encontrados"
    fi
    
    echo "   ✅ Superset configurado!"
    echo "      URL: http://localhost:8088"
    echo "      User: admin"
    echo "      Pass: admin"
}

# -----------------------------------------------------------------------------
# 3. MINIO - Criar Buckets
# -----------------------------------------------------------------------------
configure_minio() {
    echo ""
    echo "3️⃣  Configurando MinIO..."
    
    # Aguardar MinIO estar pronto
    echo "   ⏳ Aguardando MinIO iniciar..."
    until curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; do
        sleep 3
    done
    
    # O container mc já cria os buckets, mas vamos verificar
    echo "   📦 Verificando buckets..."
    docker exec datalake-mc mc ls local 2>/dev/null && echo "   ✅ Buckets disponíveis" || echo "   ⚠️  Verificar buckets manualmente"
    
    echo "   ✅ MinIO configurado!"
    echo "      URL: http://localhost:9001"
    echo "      User: datalake"
}

# -----------------------------------------------------------------------------
# 4. KAFKA CONNECT - Verificar Status
# -----------------------------------------------------------------------------
configure_kafka_connect() {
    echo ""
    echo "4️⃣  Verificando Kafka Connect..."
    
    # Aguardar Kafka Connect
    echo "   ⏳ Aguardando Kafka Connect iniciar..."
    until curl -s http://localhost:8083/connectors > /dev/null 2>&1; do
        sleep 5
    done
    
    echo "   ✅ Kafka Connect online!"
    echo "      URL: http://localhost:8083"
}

# -----------------------------------------------------------------------------
# 5. SINCRONIZAR CÓDIGO COM GITEA
# -----------------------------------------------------------------------------
sync_code_to_gitea() {
    echo ""
    echo "5️⃣  Sincronizando código com Gitea..."
    
    # Aguardar Gitea estar pronto após possível restart
    sleep 5
    until curl -s http://localhost:3000 > /dev/null 2>&1; do
        sleep 3
    done
    
    # Criar repositório via API
    echo "   📦 Criando repositório..."
    curl -s -X POST "http://localhost:3000/api/v1/user/repos" \
        -H "content-type: application/json" \
        -u "datalake_admin:DatalakeAdmin@2026" \
        -d '{"name":"datalake-fb", "private": false}' > /dev/null 2>&1 || true
    
    # Configurar git local
    cd "$PROJECT_ROOT"
    git config user.email "bot@datalake.local" 2>/dev/null || true
    git config user.name "DataLake Bot" 2>/dev/null || true
    
    # Adicionar remote se não existir
    git remote remove gitea_origin 2>/dev/null || true
    git remote add gitea_origin "http://datalake_admin:DatalakeAdmin%402026@localhost:3000/datalake_admin/datalake-fb.git"
    
    # Push
    git add . 2>/dev/null || true
    git commit -m "Auto-sync: Configuração inicial" 2>/dev/null || true
    git push -u gitea_origin main --force 2>/dev/null && echo "   ✅ Código sincronizado!" || echo "   ⚠️  Já sincronizado"
    
    echo "      Repo: http://localhost:3000/datalake_admin/datalake-fb"
}

# -----------------------------------------------------------------------------
# EXECUTAR CONFIGURAÇÕES
# -----------------------------------------------------------------------------
main() {
    configure_gitea
    configure_superset
    configure_minio
    configure_kafka_connect
    sync_code_to_gitea
    
    echo ""
    echo "=========================================="
    echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
    echo "=========================================="
    echo ""
    echo "📊 URLs de Acesso:"
    echo "   • Superset:      http://localhost:8088"
    echo "   • Trino:         http://localhost:8081"
    echo "   • Kafka UI:      http://localhost:8090"
    echo "   • MinIO:         http://localhost:9001"
    echo "   • Gitea:         http://localhost:3000"
    echo "   • Spark Master:  http://localhost:8085"
    echo "   • Datagen:       http://localhost:8000"
    echo ""
}

main "$@"
