# Userpass Authentication with MFA

OpenBao supports a [userpass](https://openbao.org/docs/auth/userpass/) authentication method which allows users to authenticate to OpenBao using a simple username and password combination. Adding [Multi-factor Authentication](https://openbao.org/docs/auth/login-mfa/) (MFA) provides an additional layer of security.

1. [Start the Example](#start-the-example)
1. [Create a User](#create-a-user)
1. [Enable MFA](#enable-mfa)
1. [Configure an MFA Client](#configure-an-mfa-client)
1. [Authenticate using MFA](#authenticate-using-mfa)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

    Once this completes there will be two containers running:
    - **openbao** - The OpenBao server.
    - **client** -  The container used to configure and test OpenBao.

# Create a User
1.  Exec into the client container using `make exec` and enable the userpass authentication method.
    ```bash
    bao auth enable userpass
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled userpass auth method at: userpass/</pre>
    </details>

1.  Create a test user.
    ```bash
    bao write auth/userpass/users/alice \
        password=testing
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/userpass/users/alice</pre>
    </details>

1.  Authenticate as the newly created user.
    ```bash
    bao login -method=userpass username=alice password=testing
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Success! You are now authenticated. The token information displayed below is already stored in the token helper. You do NOT need to run "bao login" again. Future OpenBao requests will automatically use this token.
    
    Key                    Value
    \---                    -----
    token                  s.S9hD37Vnxg6hd7ZTSqYmBnTJ
    token_accessor         XrLEbsKqSdfRcDgX5uRVtuMD
    token_duration         768h
    token_renewable        true
    token_policies         ["default"]
    identity_policies      []
    policies               ["default"]
    token_meta_username    alice</pre>
    </details>

1.  After logging in OpenBao will create an [identity](https://openbao.org/docs/concepts/identity/) for the user. Entity IDs can be listed using `bao list identity/entity/id`. Store the entity ID in an environment varible for later use.
    ```bash
    export ENTITY_ID=$(bao list -format=json identity/entity/id | jq -r .[0])
    ```

# Enable MFA
1.  We first need to configure a [TOTP MFA Method](https://openbao.org/api-docs/secret/identity/mfa/totp/#configure-totp-mfa-method).
    ```bash
    bao write identity/mfa/method/totp \
        issuer=openbao
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Key          Value
    \---          -----
    method_id    a51cfbe1-6bf1-c4a3-21c5-c7725af23255</pre>
    </details>

1.  OpenBao will generate a new MFA method ID. Store the method ID in an environment varible for later use.
    ```bash
    export METHOD_ID=$(bao list -format=json identity/mfa/method/totp | jq -r .[0])
    ```

1.  Next [create a login enforcement](https://openbao.org/api-docs/secret/identity/mfa/login-enforcement/#create-a-login-enforcement). In this example the MFA method will be enforced for all userpass authentication methods.
    ```bash
    bao write identity/mfa/login-enforcement/totp \
        auth_method_types=userpass \
        mfa_method_ids="$METHOD_ID"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Success! Data written to: identity/mfa/login-enforcement/totp</pre>
    </details>

1.  Finally, generate a MFA configuration for the user and save the result to a file.
    ```bash
    bao write -format=json -field=data \
       identity/mfa/method/totp/admin-generate \
       method_id="$METHOD_ID" \
       entity_id="$ENTITY_ID" \
       > /mfa-config/alice.json
    ```

# Configure an MFA Client
1.  Within the file `/mfa-config/alice.json` there are two fields present:

    - **barcode** - The base64 encoded QR code that can be used to configure Google Authenticator or similar
    - **url** - The OTP URL containing a secret that can be used to configure devices manually that don't support QR codes

    To create a QR code that can be scanned, decode the base64 encoded barcode and save it as a PNG using
    ```bash
    cat /mfa-config/alice.json | jq -r .barcode | base64 -d > /mfa-config/alice.png
    ```

1.  Configure your MFA application by scanning the QR code or entering the secret key contained in the URL.

# Authenticate using MFA
1.  Finally we can authenticate again as we did previously. This time however, in addition to a password you'll be prompted to enter a six digit MFA code.
    ```bash
    bao login -method=userpass username=alice password=testing
    ```
    <details>
    <summary>Sample output</summary>
    <pre>
    Initiating Interactive MFA Validation...
    Enter the passphrase for methodID "a51cfbe1-6bf1-c4a3-21c5-c7725af23255" of type "totp":

    Success! You are now authenticated. The token information displayed below is
    already stored in the token helper. You do NOT need to run "bao login" again.
    Future OpenBao requests will automatically use this token.

    Key                    Value
    \---                    -----
    token                  s.SIWqOCxc1tmBFRg61ZosBqzq
    token_accessor         fDU9i6rSo7QWQpDwAfMHqjQS
    token_duration         768h
    token_renewable        true
    token_policies         ["default"]
    identity_policies      []
    policies               ["default"]
    token_meta_username    alice</pre>
    </details>

# Stop the Example
1.  Exit the client container and stop the example using:
    ```bash
    make down
    ```