#!/usr/bin/env bash

set -e

# Create the OpenBao Postgres user.
psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
	CREATE ROLE "openbao" WITH LOGIN PASSWORD 'openbao';
    ALTER ROLE "openbao" CREATEROLE NOCREATEDB NOSUPERUSER NOREPLICATION NOBYPASSRLS;
EOSQL