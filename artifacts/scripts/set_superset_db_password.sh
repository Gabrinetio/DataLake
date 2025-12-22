#!/bin/bash
set -euo pipefail
DB_USER='superset'
DB_PASS='S8dG4pVw2bZ9xKqR5tLm3Yh0nQ_2025'
DB_NAME='superset'

# Set password for user; create if missing
su - postgres -c "psql -U postgres -c \"DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}'; ELSE ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}'; END IF; END $$;\""

# Create DB if not exists and set owner
su - postgres -c "psql -U postgres -c \"DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}') THEN CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}; ELSE ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER}; END IF; END $$;\""

# Verify
su - postgres -c "psql -U postgres -c \"\l+\""
