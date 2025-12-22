#!/bin/bash
set -euo pipefail

PATH=/opt/superset_venv/bin:$PATH
export SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py
export FLASK_APP='superset.app:create_app()'
export FLASK_ENV=production

/opt/superset_venv/bin/superset db upgrade
/opt/superset_venv/bin/superset init

# Use SUPERSET_ADMIN_PASSWORD from env or generate a strong one
SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD:-}"
if [ -z "${SUPERSET_ADMIN_PASSWORD}" ]; then
  echo "Nenhuma senha de admin fornecida em SUPERSET_ADMIN_PASSWORD; gerando temporária (salve no cofre)."
  SUPERSET_ADMIN_PASSWORD=$(python3 "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/scripts/generate_password.py" --length 32)
  echo "Senha admin gerada: ${SUPERSET_ADMIN_PASSWORD}"
fi

/opt/superset_venv/bin/superset fab create-admin --username admin --firstname Admin --lastname User --email admin@example.com --password "${SUPERSET_ADMIN_PASSWORD}" || true

systemctl daemon-reload || true
systemctl enable --now superset || true

ss -tlnp | grep 8088 || true
curl -I --max-time 5 http://localhost:8088 || true
