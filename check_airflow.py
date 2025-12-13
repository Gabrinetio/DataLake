#!/usr/bin/env python3
import sys
import os

print("Testing PostgreSQL connection and setup...")

# Tentar conectar ao PostgreSQL como postgres (peer auth)
try:
    import psycopg2
    conn = psycopg2.connect("host=localhost dbname=postgres user=postgres")
    print("PostgreSQL connection: OK")

    # Tentar criar usuário e banco
    conn.autocommit = True
    cursor = conn.cursor()

    # Verificar se usuário existe
    cursor.execute("SELECT usename FROM pg_user WHERE usename = 'airflow'")
    if cursor.fetchone():
        print("User airflow already exists")
    else:
        cursor.execute("CREATE USER airflow WITH PASSWORD 'airflow_password'")
        print("User airflow created")

    # Verificar se banco existe
    cursor.execute("SELECT datname FROM pg_database WHERE datname = 'airflow'")
    if cursor.fetchone():
        print("Database airflow already exists")
    else:
        cursor.execute("CREATE DATABASE airflow OWNER airflow")
        print("Database airflow created")

    cursor.close()
    conn.close()
    print("PostgreSQL setup completed successfully")

except Exception as e:
    print(f"PostgreSQL operations failed: {e}")
    sys.exit(1)