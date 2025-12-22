#!/bin/bash
set -euo pipefail
DB_USER='superset'
DB_PASS='S8dG4pVw2bZ9xKqR5tLm3Yh0nQ_2025'
DB_NAME='superset'

su - postgres -c "psql -U postgres -c \"ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';\"" || true
su - postgres -c "psql -U postgres -c \"ALTER DATABASE ${DB_NAME} OWNER TO ${DB_USER};\"" || true
su - postgres -c "psql -U postgres -c \"\l+\""
