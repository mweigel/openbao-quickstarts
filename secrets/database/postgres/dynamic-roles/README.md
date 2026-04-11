# Postgres Credentials Using Dynamic Roles

## Description
An demonstration of how OpenBao can be configured to issue Postgres database credentials using [dynamic roles](https://openbao.org/docs/secrets/databases). See the `openbao-init.sh` and `postgres-init.sh` scripts for details of how OpenBao and Postgres are configured. OpenBao connects to Postgres using a "root" user (called "openbao" in this example) and dynamically creates new database roles on demand when requested by client applications.

## Configuration
Ensure appropriate values are set in .env for the following environment variables:

| Environment Variable | Description |
| --- | --- |
| BAO_DEV_ROOT_TOKEN_ID | Value for initial OpenBao root token |
| POSTGRES_PASSWORD | Password for the Postgres database administrator |
| ROOT_DB_USER_PASSWORD | Password for the role OpenBao uses to connect to Postgres |

## Running the Example
After configuring the example, it can be started using podman-compose as shown below.
```bash
podman-compose up
```

## Using OpenBao's Database Secrets Engine
### Reading Postgres Credentials from OpenBao
Client applications can retrieve Postgres credentials from OpenBao. When doing so, OpenBao dynamcially creates a Postgres role and returns the username and password to the client. The client can then use the provided credentials to connect to Postgres. The credentials are valid for the duration of the associated lease and when the lease expires, the credentials can no longer be used. 
```bash
bao read database/creds/app_user

Key                Value
---                -----
lease_id           database/creds/app_user/RlICRGDjeYu4D5mJjyK2QFlQ
lease_duration     768h
lease_renewable    true
password           -8PjnIF5DxRNPQKDYvyO
username           v-token-app_user-iUdURiUfaGhYyQ2ovhVM-1775006222
```

### Logging into Postgres Using Credentials Issued by OpenBao
```bash
response="$(bao read -format=json database/creds/app_user | jq -r .data)"

export PGUSER="$(echo $response | jq -r .username)"
export PGPASSWORD="$(echo $response | jq -r .password)"

psql -h postgres -p 5432 postgres -w
```

### Rotating the Root User's Credentials
The credentials of the "root" user OpenBao uses to dynamically create Postgres roles can themselves be rotated.
```bash
bao write -f database/rotate-root/example-postgres-db
```

## Stop OpenBao and Postgres Containers
```bash
podman-compose down
```