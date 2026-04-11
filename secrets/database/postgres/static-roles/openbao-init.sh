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

# Create a static role.
bao write database/static-roles/app_user \
    username="app_user" \
    rotation_period="10m" \
    db_name="postgres-db" \
    rotation_statements="ALTER ROLE \"{{name}}\" WITH PASSWORD '{{password}}';"

sleep infinity