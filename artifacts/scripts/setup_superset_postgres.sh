#!/bin/bash
set -euo pipefail
DB_USER='superset'
DB_PASS='S8dG4pVw2bZ9xKqR5tLm3Yh0nQ_2025'
DB_NAME='superset'
VENV_PATH='/opt/superset_venv'
CONFIG_DIR='/opt/superset/config'
CONFIG_FILE="$CONFIG_DIR/superset_config.py"

# Check postgres
if ! ss -tlnp | grep -q 5432; then
  echo 'Postgres is not listening on 5432'; exit 1
fi

# Create role and DB if missing
ROLE_EXISTS=$(su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'\"") || true
if [ "${ROLE_EXISTS}" != "1" ]; then
  su - postgres -c "psql -U postgres -c \"CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';\""
else
  # Ensure password is set/updated if role already exists
  su - postgres -c "psql -U postgres -c \"ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';\"" || true
fi
DB_EXISTS=$(su - postgres -c "psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'\"") || true
if [ "${DB_EXISTS}" != "1" ]; then
  su - postgres -c "psql -U postgres -c \"CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};\""
fi

# Create venv and install superset
python3 -m venv ${VENV_PATH}
${VENV_PATH}/bin/pip install -U pip setuptools wheel
# Pin marshmallow to a 3.x release to prevent marshmallow v4/kwargs incompat issues
${VENV_PATH}/bin/pip install "marshmallow==3.20.1"
${VENV_PATH}/bin/pip install apache-superset==3.1.0 psycopg2-binary

# Configure superset
mkdir -p ${CONFIG_DIR}
SECRET_KEY=$(${VENV_PATH}/bin/python - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)
export DB_PASS
# URL-encode the DB password for inclusion in the SQLAlchemy URI
ENC_DB_PASS=$(${VENV_PATH}/bin/python - <<'PY'
import os, urllib.parse
print(urllib.parse.quote_plus(os.environ['DB_PASS']))
PY
)
cat > ${CONFIG_FILE} <<CFG
SECRET_KEY = "${SECRET_KEY}"
SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://${DB_USER}:${ENC_DB_PASS}@localhost:5432/${DB_NAME}"
CFG
chown -R root:root ${CONFIG_DIR} ${CONFIG_FILE}

# DB upgrade & init
export PATH=${VENV_PATH}/bin:$PATH
export SUPERSET_CONFIG_PATH=${CONFIG_FILE}
${VENV_PATH}/bin/superset db upgrade
${VENV_PATH}/bin/superset init
# Create admin user with provided password or generate a temporary one
SUPERSET_ADMIN_PASSWORD="${SUPERSET_ADMIN_PASSWORD:-}"
if [ -z "${SUPERSET_ADMIN_PASSWORD}" ]; then
  echo "Nenhuma senha de admin fornecida em SUPERSET_ADMIN_PASSWORD; gerando temporária (salve no cofre)."
  SUPERSET_ADMIN_PASSWORD=$(python3 "$(git rev-parse --show-toplevel 2>/dev/null || echo .)/scripts/generate_password.py" --length 32)
  echo "Senha admin gerada: ${SUPERSET_ADMIN_PASSWORD}"
fi

${VENV_PATH}/bin/superset fab create-admin --username admin --firstname Admin --lastname User --email admin@example.com --password "${SUPERSET_ADMIN_PASSWORD}" || true

# Create systemd service
cat > /etc/systemd/system/superset.service <<'SVC'
[Unit]
Description=Apache Superset
After=network.target

[Service]
User=root
Group=root
Environment="PATH=/opt/superset_venv/bin"
Environment="SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py"
WorkingDirectory=/opt/superset
ExecStart=/opt/superset_venv/bin/gunicorn "superset.app:create_app()" -w 4 -b 0.0.0.0:8088 --timeout 120
Restart=always

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable --now superset

# Verify
ss -tlnp | grep 8088 || true
curl -I --max-time 5 http://localhost:8088 || true
