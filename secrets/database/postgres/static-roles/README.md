# Postgres Credentials Using Static Roles

## Description
A demonstration of how OpenBao can be configured to issue Postgres database credentials using [static roles](https://openbao.org/docs/secrets/databases/#static-roles). See the `openbao-init.sh` and `postgres-init.sh` scripts for details of how OpenBao and Postgres are configured. OpenBao connects to Postgres using a "root" user (called "openbao" in this example) and rotates the passwords of existing Postgres roles on a defined schedule.

## Configuration
Ensure appropriate values are set in .env for the following environment variables:

| Environment Variable | Description |
| --- | --- |
| BAO_DEV_ROOT_TOKEN_ID | Value for initial OpenBao root token |
| POSTGRES_PASSWORD | Password for the Postgres database administrator |
| ROOT_DB_USER_PASSWORD | Password for the Postgres role OpenBao uses to connect to Postgres |

## Running the Example
After configuring the example, it can be started as shown below.
```bash
make up
```

## Using OpenBao's Database Secrets Engine
Get shell within the example-init container
```bash
make exec
```

### Reading Postgres Credentials from OpenBao
Client applications can retrieve Postgres credentials from OpenBao. When doing so, OpenBao returns the username and password of an existing Postgres role along with a TTL indicating how long the password is valid for. When the TTL reaches zero, OpenBao will rotate the password. Note that there is no OpenBao lease associated with these credentials.
```bash
bao read database/static-creds/app_user

Key                    Value
---                    -----
last_vault_rotation    2026-04-01T01:06:20.921558415Z
password               u7pG-0ZMAJxC-m3uZdHX
rotation_period        5m
ttl                    38s
username               app_user
```

### Logging into Postgres Using Credentials Issued by OpenBao
```bash
export PGUSER=app_user
export PGPASSWORD="$(bao read -field=password database/static-creds/app_user)"

psql -h postgres -p 5432 postgres -w
```

### Rotating the Root User's Credentials
The credentials of the "root" user OpenBao uses to dynamically create Postgres roles can themselves be rotated.
```bash
bao write -f database/rotate-root/example-postgres-db
```

## Stop the Example
```bash
make down
```