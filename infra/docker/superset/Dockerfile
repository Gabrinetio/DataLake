FROM apache/superset:latest

USER root

# Install pip into the venv and then install required packages
RUN apt-get update && apt-get install -y python3-pip && \
    /app/.venv/bin/python -m ensurepip --upgrade && \
    /app/.venv/bin/python -m pip install --upgrade pip && \
    /app/.venv/bin/python -m pip install psycopg2-binary trino sqlalchemy-trino && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Setup Scripts for RBAC/Assets
COPY superset/setup_superset_roles.py /app/
COPY superset/setup_superset_assets.py /app/

USER superset
