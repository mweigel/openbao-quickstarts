# Postgres Credentials Using Static Roles

OpenBao can be configured to provide Postgres database credentials using [static roles](https://openbao.org/docs/secrets/databases/#static-roles). When static roles are in use, OpenBao connects to Postgres and rotates the passwords of existing Postgres roles on a defined schedule.

1. [Start the Example](#start-the-example)
1. [Configure the Database Secrets Engine](#configure-the-database-secrets-engine)
1. [Reading Postgres Credentials from OpenBao](#reading-postgres-credentials-from-openbao)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

    Once this completes there will be three containers running:
    - **openbao** - The OpenBao server.
    - **postgres** - The Postgres server.
    - **client** -  The container used to test retrieving credentials from OpenBao and connecting to Postgres.

    The [root user](https://openbao.org/api-docs/secret/databases/#common-fields) that is used by OpenBao to connect to Postgres and the [static user](https://openbao.org/api-docs/secret/databases/#create-static-role) which OpenBao will provide credentials for will have been configured automatically in Postgres. To see the values used and how they're configured check the [compose.yaml](compose.yaml) and [postgres-init.sh](postgres-init.sh) files.

# Configure the Database Secrets Engine
1.  Exec into the openbao container using `make exec-openbao` and enable the database secrets engine.
    ```bash
    bao secrets enable database
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled the database secrets engine at: database/</pre>
    </details>

1.  Configure a connection to Postgres.
    ```bash
    bao write database/config/postgres-db \
        plugin_name="postgresql-database-plugin" \
        allowed_roles="*" \
        connection_url="postgresql://{{username}}:{{password}}@postgres:5432/postgres" \
        username="openbao" \
        password="openbao" \
        password_authentication="scram-sha-256"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: database/config/postgres-db</pre>
    </details>

1.  Configure a static role.
    ```bash
    bao write database/static-roles/app \
        username="app" \
        rotation_period="10m" \
        db_name="postgres-db" \
        rotation_statements="ALTER ROLE \"{{name}}\" WITH PASSWORD '{{password}}';"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: database/static-roles/app</pre>
    </details>

1.  Exit the openbao container.

# Reading Postgres Credentials from OpenBao
We can now retrieve Postgres credentials for our static role from OpenBao.

1.  Exec into the client container using `make exec-client` and retrieve Postgres credentials. The username, current password and TTL are returned. Once the TTL reaches zero, OpenBao will automatically rotate the password of the static role. Note that there is no [lease](https://openbao.org/docs/concepts/lease/) associated with a static role's credentials.
    ```bash
    bao read database/static-creds/app
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Key                    Value
    ---                    -----
    last_vault_rotation    2026-04-01T01:06:20.921558415Z
    password               u7pG-0ZMAJxC-m3uZdHX
    rotation_period        10m
    ttl                    38s
    username               app</pre>
    </details>

1.  Test authenticating to Postgres using the provided credentials.
    ```bash
    export PGUSER=app
    export PGPASSWORD="$(bao read -field=password database/static-creds/app)"

    psql -h postgres -p 5432 postgres -w
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    psql (18.3)
    Type "help" for help.
    postgres=></pre>
    </details>

# Stop the Example
1.  Exit the client container and stop the example.
    ```bash
    make down
    ```