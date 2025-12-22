#!/bin/bash
set -euo pipefail

# Instala e habilita Redis
if ! command -v redis-server >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server || true
fi
systemctl enable --now redis-server || true

# Configure Redis password? For now we keep it local and no-password

# Append Celery/Redis config to superset_config.py
CONFIG_FILE="/opt/superset/config/superset_config.py"
if ! grep -q "CELERY_BROKER_URL" "$CONFIG_FILE"; then
  cat >> "$CONFIG_FILE" <<'CFG'
# Redis / Celery / Caching configuration
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/1"
RESULTS_BACKEND = "redis://localhost:6379/1"
CACHE_CONFIG = {
  'CACHE_TYPE': 'RedisCache',
  'CACHE_REDIS_URL': 'redis://localhost:6379/0',
  'CACHE_DEFAULT_TIMEOUT': 300,
}
# Flask-Limiter storage via Redis
RATELIMIT_STORAGE_URL = "redis://localhost:6379/2"
# Feature flags: enable async queries
FEATURE_FLAGS = globals().get('FEATURE_FLAGS', {})
FEATURE_FLAGS.update({
  'ENABLE_ASYNC_QUERIES': True,
})
CFG
fi
chown root:root "$CONFIG_FILE"

# Create systemd unit for celery worker
cat > /etc/systemd/system/superset-celery-worker.service <<'SVC'
[Unit]
Description=Superset Celery Worker
After=network.target

[Service]
User=root
Group=root
Environment="PATH=/opt/superset_venv/bin"
Environment="SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py"
WorkingDirectory=/opt/superset
ExecStart=/opt/superset_venv/bin/celery -A superset.tasks.celery_app:app worker --loglevel=info --concurrency=4
Restart=always

[Install]
WantedBy=multi-user.target
SVC

# Create systemd unit for celery beat
cat > /etc/systemd/system/superset-celery-beat.service <<'SVC'
[Unit]
Description=Superset Celery Beat
After=network.target

[Service]
User=root
Group=root
Environment="PATH=/opt/superset_venv/bin"
Environment="SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py"
WorkingDirectory=/opt/superset
ExecStart=/opt/superset_venv/bin/celery -A superset.tasks.celery_app:app beat --loglevel=info
Restart=always

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable --now superset-celery-worker superset-celery-beat || true

# Verify services
systemctl status superset-celery-worker --no-pager || true
systemctl status superset-celery-beat --no-pager || true

# Basic check: list celery workers via `celery -A ... inspect ping`
/opt/superset_venv/bin/celery -A superset.tasks.celery_app:app -q inspect ping || true

# Print last logs
journalctl -u superset-celery-worker -n 100 --no-pager || true
journalctl -u superset-celery-beat -n 100 --no-pager || true
