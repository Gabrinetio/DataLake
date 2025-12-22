#!/bin/bash
set -euo pipefail
CONFIG_FILE=/opt/superset/config/superset_config.py
DB_USER='superset'
DB_PASS='S8dG4pVw2bZ9xKqR5tLm3Yh0nQ_2025'
DB_NAME='superset'
mkdir -p /opt/superset/config
export DB_PASS
ENC_PW=$(python3 - <<PY
import os, urllib.parse
print(urllib.parse.quote_plus(os.environ['DB_PASS']))
PY
)
cat > ${CONFIG_FILE} <<CFG
SECRET_KEY = "$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://${DB_USER}:${ENC_PW}@localhost:5432/${DB_NAME}"
CFG
chown -R root:root /opt/superset/config
ls -l /opt/superset/config
cat /opt/superset/config/superset_config.py
