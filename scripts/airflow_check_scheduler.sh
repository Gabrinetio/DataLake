#!/usr/bin/env bash
set -euo pipefail

# Tails scheduler log and prints status of airflow-scheduler via systemctl
# Usage: airflow_check_scheduler.sh --proxmox root@192.168.4.25 --ct 116 [--lines 100]

PROXMOX=""
CT=""
LINES=200

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxmox) PROXMOX="$2"; shift 2;;
    --ct) CT="$2"; shift 2;;
    --lines) LINES="$2"; shift 2;;
    -h|--help) echo "Usage: $0 --proxmox <proxmox_host> --ct <ct_id> [--lines <n>]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$PROXMOX" || -z "$CT" ]]; then
  echo "Missing required args"; exit 1
fi

echo "== systemctl status airflow-scheduler =="
ssh "$PROXMOX" "pct exec $CT -- systemctl status airflow-scheduler --no-pager || true"

echo "\n== Last $LINES lines of scheduler log(s) =="
ssh "$PROXMOX" "pct exec $CT -- bash -lc 'if [ -f /home/datalake/airflow/scheduler.log ]; then tail -n $LINES /home/datalake/airflow/scheduler.log || true; else echo \"No scheduler.log at /home/datalake/airflow/scheduler.log\"; fi'"

echo "\n== pgrep airflow scheduler processes =="
ssh "$PROXMOX" "pct exec $CT -- pgrep -a -f airflow || true"

echo "\nComplete. Check scheduler logs and systemctl output for errors."
