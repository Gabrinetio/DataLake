#!/bin/bash
set -e

grep -R "def create_celery" /opt/superset_venv/lib/python3.11/site-packages || true
grep -R "celery_app" /opt/superset_venv/lib/python3.11/site-packages || true
ls -l /opt/superset_venv/bin | grep celery || true
