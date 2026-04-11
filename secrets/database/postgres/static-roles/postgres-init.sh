#!/usr/bin/env bash

set -e

# Create the OpenBao Postgres user.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE ROLE openbao WITH LOGIN PASSWORD '${ROOT_DB_USER_PASSWORD}';
    ALTER ROLE openbao CREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION NOBYPASSRLS;
EOSQL

# Create the managed Postgres user and grant openbao the ability to manage it.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE ROLE app_user WITH LOGIN;
    ALTER ROLE app_user NOCREATEDB NOSUPERUSER NOREPLICATION NOBYPASSRLS;
    GRANT app_user TO openbao WITH ADMIN OPTION;
EOSQL