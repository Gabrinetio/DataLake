#!/bin/bash
set -euo pipefail
/opt/superset_venv/bin/pip install --force-reinstall "marshmallow==3.20.1" "marshmallow-sqlalchemy==0.28.1"
/opt/superset_venv/bin/pip show marshmallow || true
/opt/superset_venv/bin/pip freeze | grep marshmallow || true
