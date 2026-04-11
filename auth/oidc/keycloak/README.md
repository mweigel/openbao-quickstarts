# OIDC Authentication using Keycloak

## Description

A demonstration of how OIDC can be used to authenticate to OpenBao. In this example KeyCloak is used as the OIDC provider.

## Configuration
Ensure appropriate values are set in .env for the following environment variables:

| Environment Variable | Description |
| --- | --- |
| BAO_DEV_ROOT_TOKEN_ID | Value for initial OpenBao root token |
| KC_BOOTSTRAP_ADMIN_PASSWORD | Password for the Keycloak administrator |
| OIDC_USER_PASSWORD | Password for user used to authenticate to Keycloak |

## Running the Example
After configuring the example, it can be started as shown below. Keycloak may take some time to start up.
```bash
make up
```

## Using OpenBao's OIDC Authentication Method
Get shell within the example-init container
```bash
make exec
```

Authenticate to OpenBao using the `bao login` command shown below. This will start the text-based w3m browser and prompt you to enter a username and password.
```bash
bao login -method=oidc > output.txt 2>&1 & sleep 2; grep http output.txt | xargs w3m
```
The w3m display will appear as below. To submit the login form:
- Navigate to the username and password fields using the arrow keys
- Press enter to begin typing text info a field and enter again to submit
- Navigate to "Sign In" and press enter to submit the form
```
Demo Realm

Sign in to your account

Username or email
[                    ]
Password
[                    ]
Sign In
```

Once logged in successfully you will see the following
```bash
Signed in via your OIDC provider

You can now close this window and start using OpenBao.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Not sure how to get started?

Check out the official OpenBao documentation
```
Exit w3m using "Q" and check the contents of output.txt. An OpenBao token should be displayed proving that authentication was successful.

```bash
cat output.txt
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
---                  -----
token                s.9GM2aoTW1yHd9pP9T9jN7EYu
token_accessor       vTythG78TEZXdJ3JV45fp042
token_duration       768h
token_renewable      true
token_policies       ["default"]
identity_policies    []
policies             ["default"]
token_meta_role      demo-user
```

## Stop the Example
```bash
make down
```