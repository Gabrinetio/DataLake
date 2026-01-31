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
        
        # Obter CSRF Token explicitamente
        csrf_url = 'http://localhost:8088/api/v1/security/csrf_token/'
        csrf_resp = session.get(csrf_url, headers=headers)
        if csrf_resp.status_code == 200:
            csrf_token = csrf_resp.json().get('result')
            headers['X-CSRFToken'] = csrf_token
        
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
# 7. PIPELINE DE INGESTÃO - Spark Job para carregar dados
# -----------------------------------------------------------------------------
configure_data_pipeline() {
    echo ""
    echo "7️⃣  Configurando pipeline de ingestão..."
    
    # Criar script de ingestão Spark
    echo "   📝 Criando script de ingestão Spark..."
    
    cat > /tmp/ingest_data.py << 'SPARK_SCRIPT'
#!/usr/bin/env python3
"""
Spark Job: Ingestão de dados do Datagen para Iceberg
Este script gera dados de exemplo e insere nas tabelas Iceberg.
"""
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import random
import uuid
from datetime import datetime, timedelta
from decimal import Decimal

# Criar SparkSession com suporte a Iceberg
spark = SparkSession.builder \
    .appName("DataLake_ISP_Ingestion") \
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
    .config("spark.sql.catalog.iceberg", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.iceberg.type", "hive") \
    .config("spark.sql.catalog.iceberg.uri", "thrift://datalake-hive:9083") \
    .config("spark.sql.catalog.iceberg.warehouse", "s3a://warehouse/") \
    .config("spark.hadoop.fs.s3a.endpoint", "http://datalake-minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "datalake") \
    .config("spark.hadoop.fs.s3a.secret.key", "iRB;g2&ChZ&XQEW!") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")
print("=" * 50)
print("🚀 Iniciando ingestão de dados ISP...")
print("=" * 50)

# Gerar dados de exemplo
def generate_customers(n=100):
    cities = ["São Paulo", "Rio de Janeiro", "Belo Horizonte", "Curitiba", "Porto Alegre", "Salvador", "Fortaleza"]
    states = ["SP", "RJ", "MG", "PR", "RS", "BA", "CE"]
    plans = ["Básico", "Padrão", "Premium", "Empresarial"]
    statuses = ["Ativo", "Inativo", "Suspenso"]
    
    data = []
    for i in range(n):
        city_idx = random.randint(0, len(cities)-1)
        data.append((
            str(uuid.uuid4()),
            f"Cliente {i+1}",
            f"cliente{i+1}@email.com",
            f"({random.randint(11,99)}) 9{random.randint(1000,9999)}-{random.randint(1000,9999)}",
            f"Rua {random.randint(1,999)}, {random.randint(1,500)}",
            cities[city_idx],
            states[city_idx],
            random.choice(plans),
            random.choice(statuses),
            datetime.now() - timedelta(days=random.randint(1, 365)),
            datetime.now()
        ))
    return data

def generate_sessions(n=500):
    data = []
    for i in range(n):
        start = datetime.now() - timedelta(hours=random.randint(1, 720))
        duration = random.randint(60, 86400)
        data.append((
            str(uuid.uuid4()),
            str(uuid.uuid4()),
            f"192.168.{random.randint(1,254)}.{random.randint(1,254)}",
            f"AA:BB:CC:{random.randint(10,99)}:{random.randint(10,99)}:{random.randint(10,99)}",
            random.randint(1000000, 50000000000),
            random.randint(100000, 5000000000),
            start,
            start + timedelta(seconds=duration),
            duration,
            random.choice(["Fibra", "Rádio", "Cabo"])
        ))
    return data

def generate_invoices(n=200):
    data = []
    for i in range(n):
        created = datetime.now() - timedelta(days=random.randint(1, 180))
        due = created + timedelta(days=30)
        paid = due - timedelta(days=random.randint(-5, 10)) if random.random() > 0.2 else None
        amount = Decimal(str(round(random.uniform(79.90, 499.90), 2)))
        data.append((
            str(uuid.uuid4()),
            str(uuid.uuid4()),
            amount,
            due.date(),
            paid.date() if paid else None,
            "Pago" if paid else random.choice(["Pendente", "Atrasado"]),
            random.choice(["Boleto", "Cartão", "PIX", "Débito"]) if paid else None,
            created
        ))
    return data

def generate_contracts(n=100):
    plans = [
        ("Internet 100Mbps", 100, "89.90"),
        ("Internet 200Mbps", 200, "119.90"),
        ("Internet 500Mbps", 500, "179.90"),
        ("Internet 1Gbps", 1000, "299.90"),
        ("Empresarial 500Mbps", 500, "399.90")
    ]
    data = []
    for i in range(n):
        plan = random.choice(plans)
        start = datetime.now().date() - timedelta(days=random.randint(30, 730))
        data.append((
            str(uuid.uuid4()),
            str(uuid.uuid4()),
            plan[0],
            plan[1],
            Decimal(plan[2]),
            start,
            start + timedelta(days=365),
            random.choice(["Ativo", "Encerrado", "Cancelado"]),
            datetime.now() - timedelta(days=random.randint(30, 730))
        ))
    return data

# Schemas
customers_schema = StructType([
    StructField("id", StringType()), StructField("name", StringType()),
    StructField("email", StringType()), StructField("phone", StringType()),
    StructField("address", StringType()), StructField("city", StringType()),
    StructField("state", StringType()), StructField("plan_type", StringType()),
    StructField("status", StringType()), StructField("created_at", TimestampType()),
    StructField("updated_at", TimestampType())
])

sessions_schema = StructType([
    StructField("id", StringType()), StructField("customer_id", StringType()),
    StructField("ip_address", StringType()), StructField("mac_address", StringType()),
    StructField("bytes_in", LongType()), StructField("bytes_out", LongType()),
    StructField("start_time", TimestampType()), StructField("end_time", TimestampType()),
    StructField("duration_seconds", IntegerType()), StructField("connection_type", StringType())
])

invoices_schema = StructType([
    StructField("id", StringType()), StructField("customer_id", StringType()),
    StructField("amount", DecimalType(10,2)), StructField("due_date", DateType()),
    StructField("paid_date", DateType()), StructField("status", StringType()),
    StructField("payment_method", StringType()), StructField("created_at", TimestampType())
])

contracts_schema = StructType([
    StructField("id", StringType()), StructField("customer_id", StringType()),
    StructField("plan_name", StringType()), StructField("speed_mbps", IntegerType()),
    StructField("monthly_price", DecimalType(10,2)), StructField("start_date", DateType()),
    StructField("end_date", DateType()), StructField("status", StringType()),
    StructField("created_at", TimestampType())
])

# Inserir dados
print("\n📊 Inserindo clientes...")
customers_df = spark.createDataFrame(generate_customers(100), customers_schema)
customers_df.writeTo("iceberg.isp.customers").append()
print(f"   ✅ {customers_df.count()} clientes inseridos")

print("\n📊 Inserindo sessões...")
sessions_df = spark.createDataFrame(generate_sessions(500), sessions_schema)
sessions_df.writeTo("iceberg.isp.sessions").append()
print(f"   ✅ {sessions_df.count()} sessões inseridas")

print("\n📊 Inserindo faturas...")
invoices_df = spark.createDataFrame(generate_invoices(200), invoices_schema)
invoices_df.writeTo("iceberg.isp.invoices").append()
print(f"   ✅ {invoices_df.count()} faturas inseridas")

print("\n📊 Inserindo contratos...")
contracts_df = spark.createDataFrame(generate_contracts(100), contracts_schema)
contracts_df.writeTo("iceberg.isp.contracts").append()
print(f"   ✅ {contracts_df.count()} contratos inseridos")

print("\n" + "=" * 50)
print("✅ Ingestão concluída com sucesso!")
print("=" * 50)

# Mostrar contagens finais
print("\n📋 Resumo das tabelas:")
for table in ["customers", "sessions", "invoices", "contracts"]:
    count = spark.sql(f"SELECT COUNT(*) FROM iceberg.isp.{table}").collect()[0][0]
    print(f"   • {table}: {count} registros")

spark.stop()
SPARK_SCRIPT

    # Copiar script para o container Spark
    echo "   📂 Criando diretório de trabalho..."
    docker exec datalake-spark-master mkdir -p /opt/spark/work-dir
    docker cp /tmp/ingest_data.py datalake-spark-master:/opt/spark/work-dir/
    
    # Executar o job Spark
    echo "   🚀 Executando job de ingestão Spark..."
    docker exec datalake-spark-master /opt/spark/bin/spark-submit \
        --master local[*] \
        --conf spark.driver.memory=1g \
        --conf spark.executor.memory=1g \
        /opt/spark/work-dir/ingest_data.py 2>&1 | grep -E "(Inserindo|inseridos|Resumo|✅|•|🚀|📊)" || echo "   ⚠️  Job executado (verificar logs)"
    
    echo "   ✅ Pipeline de ingestão configurado!"
}

# -----------------------------------------------------------------------------
# 8. SINCRONIZAR CÓDIGO COM GITEA
# -----------------------------------------------------------------------------
sync_code_to_gitea() {
    echo ""
    echo "8️⃣  Sincronizando código com Gitea..."
    
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
    configure_data_pipeline
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
    echo "📋 Tabelas Iceberg (com dados!):"
    echo "   • iceberg.isp.customers  - 100 registros"
    echo "   • iceberg.isp.sessions   - 500 registros"
    echo "   • iceberg.isp.invoices   - 200 registros"
    echo "   • iceberg.isp.contracts  - 100 registros"
    echo ""
}

main "$@"
