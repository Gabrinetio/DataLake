#!/bin/bash
set -euo pipefail
cat > /etc/systemd/system/superset.service <<SVC
[Unit]
Description=Apache Superset
After=network.target

[Service]
User=root
Group=root
Environment=PATH=/opt/superset_venv/bin
Environment=SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py
WorkingDirectory=/opt/superset
ExecStart=/opt/superset_venv/bin/gunicorn "superset.app:create_app()" -w 4 -b 0.0.0.0:8088 --timeout 120
Restart=always

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable --now superset || true
ss -tlnp | grep 8088 || true
curl -I --max-time 5 http://localhost:8088 || true
