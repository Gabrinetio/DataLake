#!/usr/bin/env bash
set -euo pipefail

# Script para criar/atualizar a conexão do Superset com o Hive via API
# Uso:
#   SUPERSET_URL=http://localhost:8088 \
#   SUPERSET_ADMIN_USER=admin SUPERSET_ADMIN_PASSWORD="$(vault kv get -field=password secret/superset/admin)" \
#   HIVE_SQLA_URI="hive://user:pass@db-hive.gti.local:10000/default" \
#   VENV_PATH=/opt/superset_venv ./artifacts/scripts/add_superset_hive.sh

: "${SUPERSET_URL:?Please set SUPERSET_URL (ex: http://superset.gti.local:8088)}"
: "${SUPERSET_ADMIN_USER:?Please set SUPERSET_ADMIN_USER}"
: "${SUPERSET_ADMIN_PASSWORD:?Please set SUPERSET_ADMIN_PASSWORD}"
: "${HIVE_SQLA_URI:?Please set HIVE_SQLA_URI (ex: hive://user:pass@host:10000/default)}"

VENV_PATH=${VENV_PATH:-/opt/superset_venv}

echo "[superset-hive] Instalando dependências para Hive no venv (${VENV_PATH})..."
"${VENV_PATH}/bin/pip" install --upgrade pyhive thrift-sasl jq || true

echo "[superset-hive] Autenticando no Superset (${SUPERSET_URL})..."
LOGIN_JSON=$(cat <<-JSON
{"username":"${SUPERSET_ADMIN_USER}","password":"${SUPERSET_ADMIN_PASSWORD}","provider":"db","refresh":true}
JSON
)

ACCESS_TOKEN=$(curl -s -H "Content-Type: application/json" -d "${LOGIN_JSON}" "${SUPERSET_URL%/}/api/v1/security/login" | jq -r .access_token)
if [ "${ACCESS_TOKEN:-null}" = "null" ] || [ -z "${ACCESS_TOKEN}" ]; then
  echo "Falha ao autenticar no Superset. Verifique credenciais e url." >&2
  exit 1
fi

echo "[superset-hive] Criando/atualizando Database 'Hive'..."
DB_JSON=$(cat <<-JSON
{
  "database_name": "Hive",
  "sqlalchemy_uri": "${HIVE_SQLA_URI}",
  "expose_in_sqllab": true
}
JSON
)

# Criar
CREATE_RES=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "Authorization: Bearer ${ACCESS_TOKEN}" -d "${DB_JSON}" "${SUPERSET_URL%/}/api/v1/database/")
if [ "$CREATE_RES" = "201" ] || [ "$CREATE_RES" = "200" ]; then
  echo "[superset-hive] Database criado com sucesso (HTTP $CREATE_RES)."
  exit 0
fi

if [ "$CREATE_RES" = "422" ] || [ "$CREATE_RES" = "409" ]; then
  echo "[superset-hive] Entrada possivelmente existente (HTTP $CREATE_RES). Tentando atualizar..."
  DB_ID=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" "${SUPERSET_URL%/}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,value:Hive)))" | jq -r '.result[0].id')
  if [ -z "${DB_ID}" ] || [ "${DB_ID}" = "null" ]; then
    echo "[superset-hive] Não foi possível localizar database 'Hive' para atualização." >&2
    exit 1
  fi
  UPDATE_RES=$(curl -s -o /dev/null -w "%{http_code}" -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer ${ACCESS_TOKEN}" -d "${DB_JSON}" "${SUPERSET_URL%/}/api/v1/database/${DB_ID}")
  if [ "$UPDATE_RES" = "200" ]; then
    echo "[superset-hive] Database atualizado com sucesso (HTTP $UPDATE_RES)."
    exit 0
  else
    echo "[superset-hive] Falha ao atualizar Database (HTTP $UPDATE_RES)." >&2
    exit 1
  fi
fi

echo "[superset-hive] Falha desconhecida ao criar Database (HTTP $CREATE_RES)." >&2
exit 1
