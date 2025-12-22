#!/usr/bin/env bash
set -euo pipefail

# Deploy a systemd unit to run the Airflow scheduler and enable it
# Usage: setup_airflow_systemd.sh --proxmox root@192.168.4.25 --ct 116

show_help() {
  cat <<EOF
Usage: $0 --proxmox <proxmox_host> --ct <ct_id> [--component <scheduler|webserver>] [--venv <path>] [--user <user>] [--workdir <path>]
Defaults:
  component=scheduler venv=/opt/airflow_venv  user=datalake  workdir=/home/datalake/airflow
EOF
}

PROXMOX=""
CT=""
COMPONENT="scheduler"
VENV="/opt/airflow_venv"
USER="datalake"
WORKDIR="/home/datalake/airflow"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox) PROXMOX="$2"; shift 2;;
    --ct) CT="$2"; shift 2;;
    --component) COMPONENT="$2"; shift 2;;
    --venv) VENV="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    -h|--help) show_help; exit 0;;
    *) echo "Unknown arg: $1"; show_help; exit 1;;
  esac
done

if [[ -z "$PROXMOX" || -z "$CT" ]]; then
  show_help; exit 1
fi

if [[ "$COMPONENT" == "webserver" ]]; then
  UNIT_FILE="/etc/systemd/system/airflow-webserver.service"
else
  UNIT_FILE="/etc/systemd/system/airflow-scheduler.service"
fi

if [[ "$COMPONENT" == "webserver" ]]; then
  read -r -d '' UNIT_CONTENT <<'UNITEOF'
[Unit]
Description=Airflow webserver
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service

[Service]
Type=simple
User=%USER%
Group=%USER%
Environment=AIRFLOW_HOME=%WORKDIR%
Environment=PATH=%VENV%/bin:%PATH%
WorkingDirectory=%WORKDIR%
ExecStart=%VENV%/bin/airflow webserver --port 8089
Restart=always
RestartSec=5s
KillMode=process
StandardOutput=append:%WORKDIR%/webserver.log
StandardError=append:%WORKDIR%/webserver.log

[Install]
WantedBy=multi-user.target
UNITEOF
else
  read -r -d '' UNIT_CONTENT <<'UNITEOF'
[Unit]
Description=Airflow scheduler
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service

[Service]
Type=simple
User=%USER%
Group=%USER%
Environment=AIRFLOW_HOME=%WORKDIR%
Environment=PATH=%VENV%/bin:%PATH%
WorkingDirectory=%WORKDIR%
ExecStart=%VENV%/bin/airflow scheduler
Restart=always
RestartSec=5s
KillMode=process

[Install]
WantedBy=multi-user.target
UNITEOF
fi

UNIT_CONTENT=${UNIT_CONTENT//%USER%/$USER}
UNIT_CONTENT=${UNIT_CONTENT//%WORKDIR%/$WORKDIR}
UNIT_CONTENT=${UNIT_CONTENT//%VENV%/$VENV}

echo "Deployando systemd unit em CT $CT"

# Create temporary file on Proxmox host then push to CT
TMP_UNIT_HOST="/tmp/airflow-scheduler.$CT.service"
ssh "$PROXMOX" "cat > $TMP_UNIT_HOST <<'EOF'
$UNIT_CONTENT
EOF"

ssh "$PROXMOX" "pct push $CT $TMP_UNIT_HOST /tmp/airflow-scheduler.service || true; rm -f $TMP_UNIT_HOST || true; pct exec $CT -- mv /tmp/airflow-scheduler.service $UNIT_FILE || true; pct exec $CT -- systemctl daemon-reload || true; pct exec $CT -- systemctl enable --now airflow-scheduler || true; pct exec $CT -- systemctl status airflow-scheduler --no-pager || true"

echo "Serviço configurado e iniciado (verifique logs e status via systemctl)."
