#!/usr/bin/env bash
set -euo pipefail

# Gera/obtém senha do admin, opcionalmente guarda no Vault, atualiza a senha no Superset
# e cria a conexão Hive via API (usa add_superset_hive.sh).
# Executar no host do Superset (ou ajustar SSH/exec para remoto).

VENV_PATH=${VENV_PATH:-/opt/superset_venv}
SUPERSET_URL=${SUPERSET_URL:-http://localhost:8088}
SUPERSET_ADMIN_USER=${SUPERSET_ADMIN_USER:-admin}
HIVE_SQLA_URI=${HIVE_SQLA_URI:-}

if [ -z "${HIVE_SQLA_URI}" ]; then
  echo "Defina HIVE_SQLA_URI antes de rodar (ex: hive://user:pass@db-hive.gti.local:10000/default)" >&2
  exit 2
fi

# Generate password if not provided
if [ -z "${SUPERSET_ADMIN_PASSWORD:-}" ]; then
  echo "Gerando nova senha forte para admin..."
  SUPERSET_ADMIN_PASSWORD=$(python3 "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/scripts/generate_password.py" --length 32)
  echo "Senha gerada: ${SUPERSET_ADMIN_PASSWORD}"
fi

# Optional: store in Vault if available
if [ -n "${VAULT_ADDR:-}" ] && [ -n "${VAULT_TOKEN:-}" ]; then
  echo "Armazenando senha no Vault..."
  vault kv put secret/superset/admin password="${SUPERSET_ADMIN_PASSWORD}" || true
fi

echo "Salvando senha temporária localmente em /tmp/superset_admin_password.txt (permissões restritas)"
echo "${SUPERSET_ADMIN_PASSWORD}" > /tmp/superset_admin_password.txt
chmod 600 /tmp/superset_admin_password.txt

echo "Atualizando senha do admin no host local (rodar dentro do venv)..."
if [ -x "${VENV_PATH}/bin/python" ]; then
  # Prefer local copy in /root if present (pushed via pct), fallback to repo path
  if [ -f "/root/reset_superset_admin.py" ]; then
    "${VENV_PATH}/bin/python" "/root/reset_superset_admin.py"
  else
    "${VENV_PATH}/bin/python" "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/artifacts/scripts/reset_superset_admin.py"
  fi
else
  echo "Venv não encontrado em ${VENV_PATH}; por favor execute reset_superset_admin.py no host do Superset dentro do venv." >&2
fi

echo "Criando/atualizando conexão Hive no Superset via API..."
# Use pushed script in /root if available (safer in remote runs)
if [ -x "/root/add_superset_hive.sh" ]; then
  SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD}" SUPERSET_URL="${SUPERSET_URL}" SUPERSET_ADMIN_USER="${SUPERSET_ADMIN_USER}" HIVE_SQLA_URI="${HIVE_SQLA_URI}" VENV_PATH="${VENV_PATH}" /root/add_superset_hive.sh
else
  SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD}" SUPERSET_URL="${SUPERSET_URL}" SUPERSET_ADMIN_USER="${SUPERSET_ADMIN_USER}" HIVE_SQLA_URI="${HIVE_SQLA_URI}" VENV_PATH="${VENV_PATH}" "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/artifacts/scripts/add_superset_hive.sh"
fi

echo "Integração finalizada. Lembre-se de armazenar a senha no cofre e remover /tmp/superset_admin_password.txt quando feito." 
