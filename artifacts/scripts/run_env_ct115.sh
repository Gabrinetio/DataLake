#!/usr/bin/env bash
set -euo pipefail

# Helper to run rotate script with precise env values inside CT 115
HIVE_SQLA_URI='hive://hive:S3cureHivePass2025@db-hive.gti.local:10000/default'
SUPERSET_ADMIN_PASSWORD='Zf7Qp9Rk2Tn6Vb8Xy4Lm3Hs0Pq1W2Z3Y'
VENV_PATH=/opt/superset_venv

export HIVE_SQLA_URI SUPERSET_ADMIN_PASSWORD VENV_PATH

echo "Running rotate_and_integrate_superset.sh with:" 
echo "  HIVE_SQLA_URI=$HIVE_SQLA_URI"
echo "  SUPERSET_ADMIN_PASSWORD=(redacted)"

/root/rotate_and_integrate_superset.sh
