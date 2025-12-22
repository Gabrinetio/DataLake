#!/usr/bin/env bash
set -euo pipefail

# Criar PR para chore/minio-spark-vault-20251222
TOKEN='7dd48af5aa94d76b5ffc56bb45883573d80e1dc3'
API='http://127.0.0.1:3000/api/v1/repos/gitea/Datalake_FB/pulls'

curl -sS -X POST -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -d @- "$API" <<'JSON'
{
  "title": "chore: rotate MinIO/Spark/Hive secrets",
  "head": "chore/minio-spark-vault-20251222",
  "base": "main",
  "body": "Aplica rotação de segredos e correções relacionadas (MinIO verifier, SPARK_WORKER_OPTS)."
}
JSON
