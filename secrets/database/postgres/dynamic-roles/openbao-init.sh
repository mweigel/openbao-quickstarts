#!/usr/bin/env sh

# Enable the database secrets engine.
bao secrets enable database

# Configure a connection to the Postgres database.
bao write database/config/postgres-db \
    plugin_name="postgresql-database-plugin" \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres" \
    username="openbao" \
    password="${ROOT_DB_USER_PASSWORD}" \
    password_authentication="scram-sha-256"

# Create a dynamic role.
bao write database/roles/app_user \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
    revocation_statements="DROP ROLE IF EXISTS \"{{name}}\";" \
    renewal_statements="ALTER ROLE \"{{name}}\" VALID UNTIL '{{expiration}}';" \
    username="app_user" \
    rotation_period="5m" \
    db_name="postgres-db" \
    rotation_statements="ALTER ROLE \"{{name}}\" WITH PASSWORD '{{password}}';"

sleep infinity