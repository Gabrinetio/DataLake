#!/usr/bin/env bash
set -euo pipefail

# Full integration helper for CT 115
# Generates SECRET_KEY, installs pyhive, creates admin, adds Hive DB, lists DBs/users and tests Hive connectivity

HIVE_SQLA_URI_DEFAULT='hive://hive@db-hive.gti.local:10000/default?auth=NOSASL'
HIVE_SQLA_URI=${HIVE_SQLA_URI:-$HIVE_SQLA_URI_DEFAULT}
SUPERSET_URL=${SUPERSET_URL:-http://localhost:8088}

echo "[integration] Generating SECRET_KEY..."
SECRET_KEY=$(python3 - <<'PY'
import secrets,base64
print(base64.b64encode(secrets.token_bytes(32)).decode())
PY
)
echo "[integration] SECRET_KEY generated"

cat > /root/superset_temp_config.py <<EOF
SECRET_KEY='${SECRET_KEY}'
EOF

echo "[integration] Installing pyhive and thrift-sasl in venv..."
/opt/superset_venv/bin/pip install --upgrade pyhive thrift-sasl jq || true

export SUPERSET_CONFIG_PATH=/root/superset_temp_config.py
export FLASK_APP='superset.app:create_app()'

echo "[integration] Ensuring admin exists (creating/updating)..."
/opt/superset_venv/bin/superset fab create-admin --username admin --firstname Admin --lastname User --email admin@example.com --password "${SUPERSET_ADMIN_PASSWORD:-ChangeMe2025!}" || true

if [ -x /root/add_superset_hive.sh ]; then
  echo "[integration] Adding Hive DB via /root/add_superset_hive.sh"
  SUPERSET_URL="$SUPERSET_URL" \
  HIVE_SQLA_URI="$HIVE_SQLA_URI" \
  SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD:-ChangeMe2025!}" \
  /root/add_superset_hive.sh || true
else
  echo "[integration] /root/add_superset_hive.sh not found"
fi

echo "[integration] Listing Superset DBs"
/opt/superset_venv/bin/python /root/list_superset_dbs.py || true

echo "[integration] Listing Superset users"
env PATH=/opt/superset_venv/bin:$PATH FLASK_APP='superset.app:create_app()' /opt/superset_venv/bin/superset fab list-users || true

echo "[integration] Testing Hive connection"
export HIVE_SQLA_URI="$HIVE_SQLA_URI"
/opt/superset_venv/bin/python /root/test_hive_sqlalchemy.py || true

echo "[integration] Done"
