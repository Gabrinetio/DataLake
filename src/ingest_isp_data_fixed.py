#!/usr/bin/env python3
"""
Spark Job: Ingestão de dados do Datagen para Iceberg (CORRIGIDO)
Este script gera dados de exemplo e insere nas tabelas Iceberg.
"""
from pyspark.sql import SparkSession
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
    .config("spark.hadoop.fs.s3a.endpoint", "http://minio:9000") \
    .config("spark.hadoop.fs.s3a.access.key", "datalake") \
    .config("spark.hadoop.fs.s3a.secret.key", "datalake_minio_admin_2026") \
    .config("spark.hadoop.fs.s3a.path.style.access", "true") \
    .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem") \
    .config("spark.hadoop.fs.s3a.connection.ssl.enabled", "false") \
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

# Inserir dados usando schema da tabela existente
print("\n📊 Inserindo clientes...")
try:
    customers_data = generate_customers(100)
    customers_df = spark.createDataFrame(customers_data, spark.table("iceberg.isp.customers").schema)
    customers_df.writeTo("iceberg.isp.customers").append()
    print(f"   ✅ {len(customers_data)} clientes inseridos")
except Exception as e:
    print(f"   ❌ Erro em clientes: {e}")

print("\n📊 Inserindo sessões...")
try:
    sessions_data = generate_sessions(500)
    sessions_df = spark.createDataFrame(sessions_data, spark.table("iceberg.isp.sessions").schema)
    sessions_df.writeTo("iceberg.isp.sessions").append()
    print(f"   ✅ {len(sessions_data)} sessões inseridas")
except Exception as e:
    print(f"   ❌ Erro em sessões: {e}")

print("\n📊 Inserindo faturas...")
try:
    invoices_data = generate_invoices(200)
    invoices_df = spark.createDataFrame(invoices_data, spark.table("iceberg.isp.invoices").schema)
    invoices_df.writeTo("iceberg.isp.invoices").append()
    print(f"   ✅ {len(invoices_data)} faturas inseridas")
except Exception as e:
    print(f"   ❌ Erro em faturas: {e}")

print("\n📊 Inserindo contratos...")
try:
    contracts_data = generate_contracts(100)
    contracts_df = spark.createDataFrame(contracts_data, spark.table("iceberg.isp.contracts").schema)
    contracts_df.writeTo("iceberg.isp.contracts").append()
    print(f"   ✅ {len(contracts_data)} contratos inseridos")
except Exception as e:
    print(f"   ❌ Erro em contratos: {e}")

print("\n" + "=" * 50)
print("✅ Ingestão concluída com sucesso!")
print("=" * 50)

# Mostrar contagens finais
print("\n📋 Resumo das tabelas:")
for table in ["customers", "sessions", "invoices", "contracts"]:
    try:
        count = spark.sql(f"SELECT COUNT(*) FROM iceberg.isp.{table}").collect()[0][0]
        print(f"   • {table}: {count} registros")
    except Exception as e:
        print(f"   ⚠️  Erro ao contar {table}: {e}")

spark.stop()
