#!/bin/bash
set -euo pipefail

# Check port
ss -tlnp | grep 8088 || true
# Check systemd
systemctl status superset --no-pager || true
# Check gunicorn
ps aux | grep gunicorn | grep -v grep || true
# Show venv location
ls -l /opt/superset_venv/bin/superset || true
# Show config
cat /opt/superset/config/superset_config.py || true
# Show superset users
PATH=/opt/superset_venv/bin:$PATH
export SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py
export FLASK_APP='superset.app:create_app()'
/opt/superset_venv/bin/superset fab list-users || true
# Check DB with psql
PGPASSWORD='S8^dG4#pVw2bZ9!xKqR5@tLm3Yh0&nQ' psql -h localhost -U superset -d superset -c '\dt' || true
