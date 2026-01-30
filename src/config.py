"""
Configuração centralizada para testes e scripts
Carrega variáveis de ambiente com fallbacks seguros
"""

import os
from pathlib import Path

# Carregar .env se existir
env_path = Path(__file__).parent.parent / ".env"
if env_path.exists():
    from dotenv import load_dotenv
    load_dotenv(env_path)

# ========================================
# CONFIGURAÇÃO DO HIVE METASTORE
# ========================================

HIVE_DB_HOST = os.getenv("HIVE_DB_HOST", "localhost")
HIVE_DB_PORT = int(os.getenv("HIVE_DB_PORT", "3306"))
HIVE_DB_NAME = os.getenv("HIVE_DB_NAME", "metastore")
HIVE_DB_USER = os.getenv("HIVE_DB_USER", "hive")
HIVE_DB_PASSWORD = os.getenv("HIVE_DB_PASSWORD")

# Validação de credenciais obrigatórias
# Removida validação automática - será feita apenas quando necessária

# ========================================
# CONFIGURAÇÃO MINIO / S3A
# ========================================

S3A_ACCESS_KEY = os.getenv("S3A_ACCESS_KEY", "datalake")
S3A_SECRET_KEY = os.getenv("S3A_SECRET_KEY")
S3A_ENDPOINT = os.getenv("S3A_ENDPOINT", "http://minio.gti.local:9000")
S3A_PATH_STYLE_ACCESS = os.getenv("S3A_PATH_STYLE_ACCESS", "true").lower() == "true"

if not S3A_SECRET_KEY:
    raise RuntimeError("S3A_SECRET_KEY não está definida no ambiente. Defina S3A_SECRET_KEY ou configure o Vault para fornecer a credencial.")

# ========================================
# CONFIGURAÇÃO DO SPARK
# ========================================

SPARK_WAREHOUSE_PATH = os.getenv("SPARK_WAREHOUSE_PATH", "s3a://datalake/warehouse")

# Configurações recomendadas para Spark com Iceberg
SPARK_CONFIG = {
    "spark.sql.catalogImplementation": "hive",
    "spark.sql.catalog.spark_catalog": "org.apache.iceberg.spark.SparkSessionCatalog",
    "spark.sql.catalog.spark_catalog.type": "hadoop",
    "spark.sql.catalog.spark_catalog.warehouse": SPARK_WAREHOUSE_PATH,
    "spark.hadoop.fs.s3a.endpoint": S3A_ENDPOINT,
    "spark.hadoop.fs.s3a.access.key": S3A_ACCESS_KEY,
    "spark.hadoop.fs.s3a.secret.key": S3A_SECRET_KEY,
    "spark.hadoop.fs.s3a.path.style.access": str(S3A_PATH_STYLE_ACCESS).lower(),
}

# ========================================
# CONFIGURAÇÃO KAFKA (se necessário)
# ========================================

KAFKA_BROKER = os.getenv("KAFKA_BROKER", "192.168.4.34:9092")
KAFKA_SECURITY_PROTOCOL = os.getenv("KAFKA_SECURITY_PROTOCOL", "PLAINTEXT")
KAFKA_TOPICS = {
    "cdc_vendas": "cdc.vendas",
    "cdc_clientes": "cdc.clientes", 
    "cdc_pedidos": "cdc.pedidos"
}

# ========================================
# FUNÇÕES AUXILIARES
# ========================================

def get_hive_jdbc_url():
    """Retorna a URL JDBC para Hive Metastore"""
    return f"jdbc:mariadb://{HIVE_DB_HOST}:{HIVE_DB_PORT}/{HIVE_DB_NAME}"

def get_spark_s3_config():
    """Retorna dicionário com configurações S3A para Spark"""
    return SPARK_CONFIG

def validate_env(required_only=False):
    """Valida que todas as variáveis obrigatórias estão configuradas"""
    required = [
        ("HIVE_DB_PASSWORD", HIVE_DB_PASSWORD),
        ("S3A_SECRET_KEY", S3A_SECRET_KEY),
    ]
    
    if required_only:
        # Para testes que não precisam de Hive/S3, só validar se as variáveis existem
        missing = [name for name, value in required if not value]
    else:
        missing = [name for name, value in required if not value]
    
    if missing and not required_only:
        raise ValueError(f"Variáveis de ambiente obrigatórias não configuradas: {', '.join(missing)}")
    
    return len(missing) == 0

if __name__ == "__main__":
    # Teste de configuração
    try:
        validate_env()
        print("✅ Todas as configurações estão válidas")
        print(f"   - Hive: {HIVE_DB_USER}@{HIVE_DB_HOST}:{HIVE_DB_PORT}/{HIVE_DB_NAME}")
        print(f"   - S3A: {S3A_ACCESS_KEY}@{S3A_ENDPOINT}")
        print(f"   - Warehouse: {SPARK_WAREHOUSE_PATH}")
    except ValueError as e:
        print(f"❌ Erro de configuração: {e}")



