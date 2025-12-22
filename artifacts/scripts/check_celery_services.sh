#!/bin/bash
set -euo pipefail
ps aux | grep celery | grep -v grep || true
systemctl status superset-celery-worker --no-pager || true
systemctl status superset-celery-beat --no-pager || true
journalctl -u superset-celery-worker -n 200 --no-pager || true
journalctl -u superset-celery-beat -n 200 --no-pager || true
