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
# 5. SUPERSET - Configurar Conexão Trino
# -----------------------------------------------------------------------------
configure_superset_database() {
    echo ""
    echo "5️⃣  Configurando conexão Trino no Superset..."
    
    # Aguardar Superset estar healthy
    echo "   ⏳ Aguardando Superset ficar healthy..."
    until docker exec datalake-superset curl -s http://localhost:8088/health > /dev/null 2>&1; do
        sleep 5
    done
    
    # Executar script Python para criar a conexão via API
    docker exec datalake-superset /app/.venv/bin/python -c "
import requests
import json

# Login e obter CSRF token
session = requests.Session()
login_url = 'http://localhost:8088/api/v1/security/login'
login_data = {'username': 'admin', 'password': 'admin', 'provider': 'db', 'refresh': True}

try:
    resp = session.post(login_url, json=login_data)
    if resp.status_code == 200:
        token = resp.json().get('access_token')
        headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
        
        # Verificar se já existe conexão Trino
        dbs_resp = session.get('http://localhost:8088/api/v1/database/', headers=headers)
        existing_dbs = dbs_resp.json().get('result', [])
        trino_exists = any(db.get('database_name') == 'Trino' for db in existing_dbs)
        
        if not trino_exists:
            # Criar conexão Trino
            db_data = {
                'database_name': 'Trino',
                'sqlalchemy_uri': 'trino://trino@datalake-trino:8080/iceberg',
                'expose_in_sqllab': True,
                'allow_ctas': True,
                'allow_cvas': True,
                'allow_dml': True
            }
            create_resp = session.post('http://localhost:8088/api/v1/database/', headers=headers, json=db_data)
            if create_resp.status_code in [200, 201]:
                print('Conexao Trino criada com sucesso!')
            else:
                print(f'Erro ao criar conexao: {create_resp.text}')
        else:
            print('Conexao Trino ja existe.')
    else:
        print(f'Erro no login: {resp.status_code}')
except Exception as e:
    print(f'Erro: {e}')
" 2>/dev/null || echo "   ⚠️  Configuração manual necessária"
    
    echo "   ✅ Conexão Trino configurada!"
}

# -----------------------------------------------------------------------------
# 6. TRINO/ICEBERG - Criar Schema e Tabelas
# -----------------------------------------------------------------------------
configure_iceberg_tables() {
    echo ""
    echo "6️⃣  Configurando tabelas Iceberg..."
    
    # Aguardar Trino estar pronto
    echo "   ⏳ Aguardando Trino iniciar..."
    until docker exec datalake-trino trino --execute "SELECT 1" > /dev/null 2>&1; do
        sleep 5
    done
    
    # Criar schema 'isp' para dados do ISP
    echo "   📦 Criando schema 'isp'..."
    docker exec datalake-trino trino --execute "CREATE SCHEMA IF NOT EXISTS iceberg.isp" 2>/dev/null || true
    
    # Criar tabelas para os dados do Datagen
    echo "   📊 Criando tabelas Iceberg..."
    
    # Tabela: customers (clientes)
    docker exec datalake-trino trino --execute "
    CREATE TABLE IF NOT EXISTS iceberg.isp.customers (
        id VARCHAR,
        name VARCHAR,
        email VARCHAR,
        phone VARCHAR,
        address VARCHAR,
        city VARCHAR,
        state VARCHAR,
        plan_type VARCHAR,
        status VARCHAR,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
    ) WITH (
        format = 'PARQUET',
        partitioning = ARRAY['month(created_at)']
    )
    " 2>/dev/null || echo "   ⚠️  Tabela customers já existe"
    
    # Tabela: sessions (sessões de conexão)
    docker exec datalake-trino trino --execute "
    CREATE TABLE IF NOT EXISTS iceberg.isp.sessions (
        id VARCHAR,
        customer_id VARCHAR,
        ip_address VARCHAR,
        mac_address VARCHAR,
        bytes_in BIGINT,
        bytes_out BIGINT,
        start_time TIMESTAMP,
        end_time TIMESTAMP,
        duration_seconds INTEGER,
        connection_type VARCHAR
    ) WITH (
        format = 'PARQUET',
        partitioning = ARRAY['day(start_time)']
    )
    " 2>/dev/null || echo "   ⚠️  Tabela sessions já existe"
    
    # Tabela: invoices (faturas)
    docker exec datalake-trino trino --execute "
    CREATE TABLE IF NOT EXISTS iceberg.isp.invoices (
        id VARCHAR,
        customer_id VARCHAR,
        amount DECIMAL(10,2),
        due_date DATE,
        paid_date DATE,
        status VARCHAR,
        payment_method VARCHAR,
        created_at TIMESTAMP
    ) WITH (
        format = 'PARQUET',
        partitioning = ARRAY['month(created_at)']
    )
    " 2>/dev/null || echo "   ⚠️  Tabela invoices já existe"
    
    # Tabela: contracts (contratos)
    docker exec datalake-trino trino --execute "
    CREATE TABLE IF NOT EXISTS iceberg.isp.contracts (
        id VARCHAR,
        customer_id VARCHAR,
        plan_name VARCHAR,
        speed_mbps INTEGER,
        monthly_price DECIMAL(10,2),
        start_date DATE,
        end_date DATE,
        status VARCHAR,
        created_at TIMESTAMP
    ) WITH (
        format = 'PARQUET',
        partitioning = ARRAY['year(start_date)']
    )
    " 2>/dev/null || echo "   ⚠️  Tabela contracts já existe"
    
    # Listar tabelas criadas
    echo "   📋 Tabelas disponíveis:"
    docker exec datalake-trino trino --execute "SHOW TABLES FROM iceberg.isp" 2>/dev/null | grep -v "^$" | sed 's/^/      • /'
    
    echo "   ✅ Tabelas Iceberg configuradas!"
}

# -----------------------------------------------------------------------------
# 7. SINCRONIZAR CÓDIGO COM GITEA
# -----------------------------------------------------------------------------
sync_code_to_gitea() {
    echo ""
    echo "7️⃣  Sincronizando código com Gitea..."
    
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
    configure_superset_database
    configure_iceberg_tables
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
    echo "📋 Tabelas Iceberg disponíveis:"
    echo "   • iceberg.isp.customers"
    echo "   • iceberg.isp.sessions"
    echo "   • iceberg.isp.invoices"
    echo "   • iceberg.isp.contracts"
    echo ""
}

main "$@"
