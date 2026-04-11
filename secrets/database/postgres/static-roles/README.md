# Postgres Credentials Using Static Roles

## Description
A demonstration of how OpenBao can be configured to issue Postgres database credentials using [static roles](https://openbao.org/docs/secrets/databases/#static-roles). See the `openbao-init.sh` and `postgres-init.sh` scripts for details of how OpenBao and Postgres are configured. OpenBao connects to Postgres using a "root" user (called "openbao" in this example) and rotates the passwords of existing Postgres roles on a defined schedule.

## Configuration
Ensure appropriate values are set in .env for the items with environment variables listed below

| Item | Value | Environment Variable | Description |
| --- | --- | --- | --- |
| OpenBao root token | N/A | BAO_DEV_ROOT_TOKEN_ID | Openbao [dev mode root token](https://openbao.org/docs/concepts/dev-server) |
| OpenBao root Postgres user | openbao | N/A | Role that OpenBao will use when [connecting to the database](https://openbao.org/api-docs/secret/databases/#configure-connection) |
| OpenBao root Postgres password | N/A | ROOT_DB_USER_PASSWORD | Password for role above |
| Client app user | app_user | N/A | Postgres role that [OpenBao will broker credentials for](https://openbao.org/api-docs/secret/databases/#create-static-role) |
| Postgres superuser | postgres | N/A | [Postgres superuser](https://hub.docker.com/_/postgres#environment-variables) |
| Postgres superuser password | N/A | POSTGRES_PASSWORD | Postgres superuser password |
| Postgres database | postgres | N/A | Postgres database |

## Running the Example
After configuring the example, it can be started as shown below.
```
make up
```

## Using OpenBao's Database Secrets Engine
To test client interaction with OpenBao and Postgres, exec into the client container.
```
make exec
```

### Reading Postgres Credentials from OpenBao
Client applications can retrieve Postgres credentials from OpenBao. When doing so, OpenBao returns the username and password of an existing Postgres role along with a TTL indicating how long the password is valid for. When the TTL reaches zero, OpenBao will rotate the password. Note that there is no lease associated with these credentials as they're rotated on a schedule.
```
bao read database/static-creds/app_user

Key                    Value
---                    -----
last_vault_rotation    2026-04-01T01:06:20.921558415Z
password               u7pG-0ZMAJxC-m3uZdHX
rotation_period        10m
ttl                    38s
username               app_user
```

### Logging into Postgres Using Credentials Issued by OpenBao
```
export PGUSER=app_user
export PGPASSWORD="$(bao read -field=password database/static-creds/app_user)"

psql -h postgres -p 5432 postgres -w
```

### Rotating Credentials
This endpoint can be used to manually trigger a rotation of the static role's password
```
bao write -f database/rotate-role/app_user
```

### Rotating the Root User's Credentials
The credentials of the "root" user OpenBao uses to manage Postgres roles can themselves be rotated.
```
bao write -f database/rotate-root/postgres-db
```

## Stop the Example
```
make down
```