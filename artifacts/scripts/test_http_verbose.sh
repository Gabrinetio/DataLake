#!/bin/bash
set -euo pipefail

echo '--- ss -tlnp'
ss -tlnp | grep 8088 || true

echo '--- curl 127.0.0.1:8088 -v'
curl -v --max-time 10 127.0.0.1:8088 || true

echo '--- curl localhost:8088 -v'
curl -v --max-time 10 localhost:8088 || true

echo '--- journalctl last 200 lines'
journalctl -u superset -n 200 --no-pager || true

echo '--- netstat (compat)'
netstat -tlnp | grep 8088 || true
