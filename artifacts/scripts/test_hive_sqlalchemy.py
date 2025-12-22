#!/usr/bin/env python3
"""Teste rápido de conexão SQLAlchemy -> Hive (PyHive)

Uso:
  HIVE_SQLA_URI='hive://user:pass@db-hive.gti.local:10000/default' python3 artifacts/scripts/test_hive_sqlalchemy.py
"""
import os
import sys
from sqlalchemy import create_engine, text

HIVE_SQLA_URI = os.environ.get("HIVE_SQLA_URI")
if not HIVE_SQLA_URI:
    print("Defina HIVE_SQLA_URI no ambiente (ex: hive://user:pass@host:10000/default)")
    sys.exit(2)

engine = create_engine(HIVE_SQLA_URI)
with engine.connect() as conn:
    try:
        res = conn.execute(text("SHOW TABLES"))
        print("Consulta executada com sucesso. Primeiras linhas:")
        for i, row in enumerate(res):
            print(row)
            if i >= 9:
                break
    except Exception as e:
        print(f"Erro na consulta: {e}")
        raise
