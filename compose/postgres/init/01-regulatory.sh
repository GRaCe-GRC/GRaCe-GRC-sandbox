#!/bin/bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 -v password="$REGULATORY_API_DB_PASSWORD" --username "$POSTGRES_USER" --dbname postgres <<'SQL'
CREATE USER regulatory_api WITH PASSWORD :'password';
CREATE DATABASE regulatory OWNER regulatory_api;
REVOKE ALL ON DATABASE regulatory FROM PUBLIC;
SQL
