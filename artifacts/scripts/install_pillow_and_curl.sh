#!/bin/bash
set -euo pipefail
PATH=/opt/superset_venv/bin:$PATH

# Install Pillow into venv
/opt/superset_venv/bin/pip install Pillow

# Ensure curl is available for testing
if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y curl || true
fi

# Restart superset to pick up new library
systemctl restart superset || true
sleep 3

# Check that service is running and accessible
ss -tlnp | grep 8088 || true
curl -I --max-time 5 http://localhost:8088 || true
