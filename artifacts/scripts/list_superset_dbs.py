#!/usr/bin/env python3
"""Lista databases configurados no Superset (usa app context).

Este script funciona quando executado dentro do venv do Superset no host onde o Superset
está instalado. Ele cria a aplicação via `create_app()` para assegurar o contexto.
"""
from superset.app import create_app
from superset import db as superset_db

app = create_app()

with app.app_context():
    res = superset_db.session.execute('select id, database_name, sqlalchemy_uri from dbs')
    for row in res:
        print(row)
