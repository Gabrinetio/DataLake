#!/bin/bash
set -euo pipefail
PATH=/opt/superset_venv/bin:$PATH
export SUPERSET_CONFIG_PATH=/opt/superset/config/superset_config.py
export FLASK_APP='superset.app:create_app()'

/opt/superset_venv/bin/python - <<'PY'
from PIL import Image
print('Pillow version:', Image.__version__)
PY

/opt/superset_venv/bin/superset fab list-users || true
