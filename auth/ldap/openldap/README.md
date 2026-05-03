# LDAP Authentication

OpenBao supports an [LDAP](https://openbao.org/docs/auth/ldap/) authentication method which allows users to authenticate to OpenBao using their LDAP or Active Directory credentials.

1. [Start the Example](#start-the-example)
1. [Configure the LDAP Authentication Method](#configure-the-ldap-authentication-method)
1. [Authenticate using LDAP](#authenticate-using-ldap)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

    Once this completes there will be three containers running:
    - **openbao** - The OpenBao server.
    - **openldap** - The OpenLDAP server.
    - **client** -  The container used to configure and test OpenBao.

# Configure the LDAP Authentication Method
1.  Exec into the openbao container using `make exec-openbao` and enable the ldap authentication method.
    ```bash
    bao auth enable ldap
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled ldap auth method at: ldap/</pre>
    </details>

1.  Configure the LDAP authentication method.
    ```bash
    bao write auth/ldap/config \
        url='ldap://openldap:389' \
        binddn='cn=openbao,ou=Users,dc=example,dc=org' \
        bindpass='password123' \
        userdn='ou=Users,dc=example,dc=org' \
        groupdn='ou=Groups,dc=example,dc=org'
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/ldap/config</pre>
    </details>

1.  Create a `developers` group.
    ```bash
    bao write auth/ldap/groups/developers policies=dev-access
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/ldap/groups/developers</pre>
    </details>

1.  Create an `administrators` group.
    ```bash
    bao write auth/ldap/groups/administrators policies=admin-access
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/ldap/groups/administrators</pre>
    </details>

1.  Exit the openbao container.

# Authenticate using LDAP
We can now authenticate using either user.

1.  Exec into the client container using `make exec-client` and authenticate as Alice. The "dev-access" policy is applied.
    ```bash
    bao login -method=ldap username=alice password=password123
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Success! You are now authenticated. The token information displayed below is
    already stored in the token helper. You do NOT need to run "bao login" again.
    Future OpenBao requests will automatically use this token.

    Key                    Value
    \---                    -----
    token                  s.nSEO86aq9Zxfu3Z8HdCZRiZU
    token_accessor         AuQC0rzRRQS72sBTGL1j8Etp
    token_duration         768h
    token_renewable        true
    token_policies         ["default" "dev-access"]
    identity_policies      []
    policies               ["default" "dev-access"]
    token_meta_username    alice</pre>
    </details>

1.  Authenticate as Bob, the "admin-access" policy is applied.
    ```bash
    bao login -method=ldap username=bob password=password123
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Success! You are now authenticated. The token information displayed below is
    already stored in the token helper. You do NOT need to run "bao login" again.
    Future OpenBao requests will automatically use this token.

    Key                    Value
    \---                    -----
    token                  s.4wgA9CX3NdyezJO1aEB0r1xe
    token_accessor         mzAbClgAwYZjOGPgT7EWjSGa
    token_duration         768h
    token_renewable        true
    token_policies         ["admin-access" "default"]
    identity_policies      []
    policies               ["admin-access" "default"]
    token_meta_username    bob</pre>
    </details>

# Stop the Example
1.  Exit the client container and stop the example using:
    ```bash
    make down
    ```