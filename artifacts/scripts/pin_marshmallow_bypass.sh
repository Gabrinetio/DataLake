#!/bin/bash
set -euo pipefail
/opt/superset_venv/bin/pip install --force-reinstall "marshmallow==3.20.1" "marshmallow-sqlalchemy==0.28.1" "SQLAlchemy==1.4.54"
/opt/superset_venv/bin/pip show SQLAlchemy || true
/opt/superset_venv/bin/pip freeze | grep -E "marshmallow|SQLAlchemy|marshmallow-sqlalchemy" || true
