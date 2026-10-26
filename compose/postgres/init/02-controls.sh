#!/bin/bash
set -euo pipefail

psql -v ON_ERROR_STOP=1 -v control_password="$CONTROL_API_DB_PASSWORD" -v mapping_password="$CONTROL_MAPPING_API_DB_PASSWORD" --username "$POSTGRES_USER" --dbname postgres <<'SQL'
CREATE USER control_api WITH PASSWORD :'control_password';
CREATE USER control_mapping_api WITH PASSWORD :'mapping_password';
CREATE DATABASE controls;
REVOKE ALL ON DATABASE controls FROM PUBLIC;
GRANT CONNECT ON DATABASE controls TO control_api, control_mapping_api;
\connect controls
REVOKE ALL ON SCHEMA public FROM PUBLIC;
CREATE SCHEMA controls AUTHORIZATION control_api;
CREATE SCHEMA control_mappings AUTHORIZATION control_mapping_api;
ALTER ROLE control_api IN DATABASE controls SET search_path = controls;
ALTER ROLE control_mapping_api IN DATABASE controls SET search_path = control_mappings;
SQL
