import os
from urllib.parse import urlparse
from minio import Minio
from minio.error import S3Error

# Configuration (usar variáveis de ambiente ou Vault; nunca hardcode)
endpoint = os.getenv("MINIO_ENDPOINT", "http://192.168.4.31:9000")
access_key = os.getenv("MINIO_ROOT_USER")
secret_key = os.getenv("MINIO_ROOT_PASSWORD")

# Sanitiza espaços acidentais em volta das credenciais
if access_key:
    access_key = access_key.strip()
if secret_key:
    secret_key = secret_key.strip()

endpoint = endpoint.strip()

# Validação de comprimento conforme limites padrão do MinIO
# (ROOT_USER: 3-20 chars, ROOT_PASSWORD: 8-40 chars)
def _validate_credentials(user: str, password: str) -> None:
    if not (3 <= len(user) <= 20):
        raise SystemExit(
            "MINIO_ROOT_USER inválido: tamanho deve estar entre 3 e 20 caracteres."
        )
    if not (8 <= len(password) <= 40):
        raise SystemExit(
            "MINIO_ROOT_PASSWORD inválido: tamanho deve estar entre 8 e 40 caracteres."
        )

print(f"Connecting to MinIO at {endpoint}...")
print(f"Using access_key={bool(access_key)}, secret_key={bool(secret_key)}")

if not access_key or not secret_key:
    raise SystemExit("Credenciais ausentes: defina MINIO_ROOT_USER e MINIO_ROOT_PASSWORD.")

_validate_credentials(access_key, secret_key)

try:
    parsed = urlparse(endpoint if "://" in endpoint else f"http://{endpoint}")
    host = parsed.hostname
    port = parsed.port
    secure = parsed.scheme == "https"
    netloc = f"{host}:{port}" if port else host

    client = Minio(
        netloc,
        access_key=access_key,
        secret_key=secret_key,
        secure=secure,
    )

    buckets = client.list_buckets()
    print("Connection Successful!")
    print("Buckets found:")
    for b in buckets:
        print(f" - {b.name}")
except S3Error as err:
    print(f"Error connecting to MinIO: {err}")
except Exception as err:
    print(f"An unexpected error occurred: {err}")
