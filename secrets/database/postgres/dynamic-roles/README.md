# Postgres Credentials Using Dynamic Roles

OpenBao can be configured to provide Postgres database credentials using [dynamic roles](https://openbao.org/docs/secrets/databases). When dynamic roles are in use, OpenBao connects to Postgres and creates new database roles on demand when requested by client applications.

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

    The [root user](https://openbao.org/api-docs/secret/databases/#common-fields) that is used by OpenBao to connect to Postgres will have been configured automatically. To see the values used and how they're configured check the [compose.yaml](compose.yaml) and [postgres-init.sh](postgres-init.sh) files.

# Configure the Database Secrets Engine
1.  Exec into the openbao container using `make exec-openbao` and enable the database secrets engine.
    ```bash
    bao secrets enable database
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled the database secrets engine at: database/</pre>
    </details>

1.  Configure the connection to Postgres.
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

1.  Configure the Postgres role.
    ```bash
    bao write database/roles/app \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
        revocation_statements="DROP ROLE IF EXISTS \"{{name}}\";" \
        renewal_statements="ALTER ROLE \"{{name}}\" VALID UNTIL '{{expiration}}';" \
        username="app" \
        rotation_period="5m" \
        db_name="postgres-db" \
        rotation_statements="ALTER ROLE \"{{name}}\" WITH PASSWORD '{{password}}';"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: database/roles/app</pre>
    </details>

1.  Exit the openbao container.

### Reading Postgres Credentials from OpenBao
We can now retrieve Postgres credentials for our dynamic role from OpenBao.

1.  Exec into the client container using `make exec-client` and retrieve Postgres credentials. The dynamically generated username, password and [lease](https://openbao.org/docs/concepts/lease/) information are returned. When the lease expires, the dynamically generated Postgres role will be automatically deleted by OpenBao.
    ```bash
    bao read database/creds/app
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Key                Value
    ---                -----
    lease_id           database/creds/app/RlICRGDjeYu4D5mJjyK2QFlQ
    lease_duration     768h
    lease_renewable    true
    password           -8PjnIF5DxRNPQKDYvyO
    username           v-token-app-iUdURiUfaGhYyQ2ovhVM-1775006222
    ```
    </details>

1.  Test authenticating to Postgres using the provided credentials.
    ```bash
    response="$(bao read -format=json database/creds/app | jq -r .data)"

    export PGUSER="$(echo $response | jq -r .username)"
    export PGPASSWORD="$(echo $response | jq -r .password)"

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