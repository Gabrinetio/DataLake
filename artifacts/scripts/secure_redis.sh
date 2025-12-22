#!/bin/bash
set -euo pipefail

# Secure Redis: set password, enable AOF persistence, add simple backup
# Usage: sudo bash secure_redis.sh [REDIS_PASS]

REDIS_CONF=/etc/redis/redis.conf
BACKUP_DIR=/var/backups/redis
SECRET_FILE=/opt/superset/config/redis_secret

if [ $# -ge 1 ]; then
  REDIS_PASS="$1"
else
  REDIS_PASS=$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)
fi

mkdir -p ${BACKUP_DIR}
chown root:root ${BACKUP_DIR}
chmod 700 ${BACKUP_DIR}

# Ensure we have a config file
if [ ! -f "$REDIS_CONF" ]; then
  echo "Redis config not found at $REDIS_CONF" >&2
  exit 1
fi

# Make a safe copy
cp ${REDIS_CONF} ${REDIS_CONF}.bak.$(date +%s)

# Set requirepass (idempotent)
if grep -q "^#*\s*requirepass" "$REDIS_CONF"; then
  sed -ri "s/^#?\s*requirepass\s+.*/requirepass ${REDIS_PASS}/" "$REDIS_CONF"
else
  echo "requirepass ${REDIS_PASS}" >> "$REDIS_CONF"
fi

# Enable appendonly persistence (AOF)
if grep -q "^#*\s*appendonly\s+no" "$REDIS_CONF"; then
  sed -ri "s/^#?\s*appendonly\s+.*/appendonly yes/" "$REDIS_CONF"
elif ! grep -q "^appendonly\s+yes" "$REDIS_CONF"; then
  echo "appendonly yes" >> "$REDIS_CONF"
fi

# Ensure bind to localhost only
if grep -q "^bind\s+" "$REDIS_CONF"; then
  sed -ri "s/^bind\s+.*/bind 127.0.0.1 ::1/" "$REDIS_CONF"
else
  echo "bind 127.0.0.1 ::1" >> "$REDIS_CONF"
fi

# Protected mode on
if grep -q "^#*\s*protected-mode\s+" "$REDIS_CONF"; then
  sed -ri "s/^#?\s*protected-mode\s+.*/protected-mode yes/" "$REDIS_CONF"
else
  echo "protected-mode yes" >> "$REDIS_CONF"
fi

# Write secret file for local services (owner root, mode 600)
mkdir -p $(dirname ${SECRET_FILE})
echo -n "${REDIS_PASS}" > ${SECRET_FILE}
chown root:root ${SECRET_FILE}
chmod 600 ${SECRET_FILE}

# Restart redis
systemctl restart redis-server
sleep 1

# Verify redis auth works
if command -v redis-cli >/dev/null 2>&1; then
  if redis-cli PING 2>/dev/null | grep -q PONG; then
    echo "ERROR: Redis responded to unauthenticated PING (should require auth)" >&2
  fi
  if redis-cli -a "${REDIS_PASS}" PING | grep -q PONG; then
    echo "Redis AUTH OK"
  else
    echo "Redis AUTH failed" >&2
  fi
else
  echo "redis-cli not available to test auth" >&2
fi

# Create a daily backup job
cat > /etc/cron.daily/redis-backup <<'CRON'
#!/bin/sh
BACKUP_DIR="/var/backups/redis"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +"%Y%m%dT%H%M%S")
if [ -f /var/lib/redis/dump.rdb ]; then
  cp /var/lib/redis/dump.rdb "$BACKUP_DIR/dump-$TIMESTAMP.rdb"
  chmod 600 "$BACKUP_DIR/dump-$TIMESTAMP.rdb"
fi
CRON
chmod 750 /etc/cron.daily/redis-backup

# Update Superset config to include encoded password
CONFIG_FILE=/opt/superset/config/superset_config.py
if [ -f "$CONFIG_FILE" ]; then
  ENC_PASS=$(python3 -c "import urllib.parse,os; print(urllib.parse.quote_plus('$REDIS_PASS'))")
  sed -ri "s#(CELERY_BROKER_URL\s*=\s*)\".*\"#\1\"redis://:$ENC_PASS@localhost:6379/0\"#" "$CONFIG_FILE" || true
  sed -ri "s#(CELERY_RESULT_BACKEND\s*=\s*)\".*\"#\1\"redis://:$ENC_PASS@localhost:6379/1\"#" "$CONFIG_FILE" || true
  sed -ri "s#(CACHE_REDIS_URL\s*:\s*)\'.*\'#\1'redis://:$ENC_PASS@localhost:6379/0'#" "$CONFIG_FILE" || true
  sed -ri "s#(RATELIMIT_STORAGE_URL\s*=\s*)\".*\"#\1\"redis://:$ENC_PASS@localhost:6379/2\"#" "$CONFIG_FILE" || true
  chown root:root "$CONFIG_FILE"
  echo "Updated $CONFIG_FILE with Redis password (URL-encoded)"
else
  echo "Superset config not found at $CONFIG_FILE; please update Redis URLs manually."
fi

# Restart Superset and Celery services to pick up new credentials
systemctl restart superset || true
systemctl restart superset-celery-worker || true
systemctl restart superset-celery-beat || true

# Final verification
echo "Services status:"
systemctl status redis-server --no-pager || true
systemctl status superset --no-pager || true
systemctl status superset-celery-worker --no-pager || true
systemctl status superset-celery-beat --no-pager || true

echo "Done. Redis password saved to ${SECRET_FILE} (root only)."
