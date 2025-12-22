#!/usr/bin/env bash
set -euo pipefail

# Script helper para executar a rotação no CT (copie para o host via scp e execute no Proxmox)
# ATENÇÃO: contém senha por motivos de execução remota; remover após uso.

HIVE_SQLA_URI='hive://hive:S3cureHivePass2025@db-hive.gti.local:10000/default'
SUPERSET_ADMIN_PASSWORD='W=HTCA5n[o-$4DoZ6Uht3z3P9qlTIENr'
VENV_PATH=/opt/superset_venv

/root/rotate_and_integrate_superset.sh
