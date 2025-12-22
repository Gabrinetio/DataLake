#!/bin/bash
/opt/superset_venv/bin/pip show marshmallow || /opt/superset_venv/bin/pip show marshmallow==3.20.1 || true
/opt/superset_venv/bin/pip freeze | grep marshmallow || true
echo "--- Flask-AppBuilder info ---"
/opt/superset_venv/bin/pip show Flask-AppBuilder || true
/opt/superset_venv/bin/pip show flask-appbuilder || true
