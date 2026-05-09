# OIDC Authentication using Keycloak

A demonstration of how OIDC can be used to authenticate to OpenBao. In this example Keycloak is used as the OIDC provider.

1. [Start the Example](#start-the-example)
1. [Configure the OIDC Authentication Method](#configure-the-oidc-authentication-method)
1. [Using OpenBao's OIDC Authentication Method](#using-openbaos-oidc-authentication-method)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

    Once this completes there will be three containers running:
    - **openbao** - The OpenBao server.
    - **keycloak** - The Keycloak server.
    - **client** - The container used to test OpenBao authentication using OIDC.

# Configure the OIDC Authentication Method
1.  Exec into the openbao container using `make exec-openbao` and enable the OIDC authentication method.
    ```bash
    bao auth enable oidc
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled oidc auth method at: oidc/</pre>
    </details>

1.  Configure the OIDC authentication method.
    ```bash
    bao write auth/oidc/config \
        oidc_client_id="openbao" \
        oidc_client_secret="openbao" \
        default_role="oidc-user" \
        oidc_discovery_url="http://keycloak:8080/realms/openbao-demo"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/oidc/config</pre>
    </details>

1.  Configure the OIDC authentication method.
    ```bash
    bao write auth/oidc/role/oidc-user \
        role_type="oidc" \
        user_claim="sub" \
        policies="default" \
        oidc_scopes="profile,email" \
        allowed_redirect_uris="http://vault:8200/v1/auth/oidc/callback,https://vault:8200/ui/vault/auth/oidc/oidc/callback,http://localhost:8250/oidc/callback"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/oidc/role/oidc-user</pre>
    </details>

1.  Exit the openbao container.

# Using OpenBao's OIDC Authentication Method
1.  To test client interaction with OpenBao and Keycloak, exec into the client container using `make exec-client`. Authenticate to OpenBao using the `bao login` command shown below. This will start the text-based browser w3m and prompt you to enter a username and password for the OIDC user.
    ```
    bao login -method=oidc > output.txt 2>&1 & sleep 2; grep http output.txt | xargs w3m
    ```

1.  The w3m display will appear as below. Navigate to the username and password fields using the arrow keys. Press enter to begin typing text info each field and enter again to submit it.
    <details open>
    <summary>Sample output</summary>
    <pre>
    Demo Realm

    Sign in to your account

    Username or email
    [oidc-user           ]
    Password
    [********            ]
    Sign In
    </pre>
    </details>

1. Navigate to `Sign In` using the arrow keys and press enter to submit the form.
    <details>
    <summary>Sample output</summary>
    <pre>Signed in via your OIDC provider

    You can now close this window and start using OpenBao.

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    Not sure how to get started?

    Check out the official OpenBao documentation
    </pre>
    </details>

1.  Exit w3m using "Q" and check the contents of `output.txt`. An OpenBao token should be displayed proving that authentication was successful.
    ```bash
    cat output.txt
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Complete the login via your OIDC provider. Launching browser to:

    http://keycloak:8080/realms/openbao-demo/protocol/openid-connect/auth?client_id=openbao&code_challenge=Neip0gwalDOSq6CwxymQvrffwnGUNX5Vgd6TWIz58sY&code_challenge_method=S256&nonce=n_FWtS0vJpbElvJkwbylBe&redirect_uri=http%3A%2F%2Flocalhost%3A8250%2Foidc%2Fcallback&response_type=code&scope=openid+profile+email&state=st_DzPbynBMxpJpVLiP6MAS

    Waiting for OIDC authentication to complete...
    WARNING! The BAO_TOKEN environment variable is set! The value of this variable
    will take precedence; if this is unwanted please unset BAO_TOKEN or update its
    value accordingly.

    Success! You are now authenticated. The token information displayed below is
    already stored in the token helper. You do NOT need to run "bao login" again.
    Future OpenBao requests will automatically use this token.

    Key                  Value
    \---                  -----
    token                s.9GM2aoTW1yHd9pP9T9jN7EYu
    token_accessor       vTythG78TEZXdJ3JV45fp042
    token_duration       768h
    token_renewable      true
    token_policies       ["default"]
    identity_policies    []
    policies             ["default"]
    token_meta_role      oidc-user</pre>
    </details>

# Stop the Example
1.  Exit the client container and stop the example.
    ```bash
    make down
    ```