# OIDC Authentication using Keycloak

## Description

A demonstration of how OIDC can be used to authenticate to OpenBao. In this example Keycloak is used as the OIDC provider.

## Configuration
Ensure appropriate values are set in .env for the items with environment variables listed below

| Item | Value | Environment Variable | Description |
| --- | --- | --- | --- |
| OpenBao root token | N/A | BAO_DEV_ROOT_TOKEN_ID | Openbao [dev mode root token](https://openbao.org/docs/concepts/dev-server) |
| Keycloak admin user | admin | N/A | [Keycloak admin user](https://www.keycloak.org/server/containers#_provide_initial_admin_credentials_when_running_in_a_container) |
|Keycloak admin password | N/A | KC_BOOTSTRAP_ADMIN_PASSWORD | Keycloak admin user password |
| OIDC user | oidc-user | N/A | Username of Keycloak OIDC user |
| OIDC user password | N/A | OIDC_USER_PASSWORD | Password of Keycloak OIDC user |

## Running the Example
After configuring the example, it can be started as shown below. Keycloak may take some time to start up.
```
make up
```

## Using OpenBao's OIDC Authentication Method
To test client interaction with OpenBao and Keycloak, exec into the client container.
```
make exec
```

Authenticate to OpenBao using the `bao login` command shown below. This will start the text-based browser w3m and prompt you to enter a username and password for the OIDC user.
```
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
[oidc-user           ]
Password
[********            ]
Sign In
```

Once logged in successfully you will see the following
```
Signed in via your OIDC provider

You can now close this window and start using OpenBao.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Not sure how to get started?

Check out the official OpenBao documentation
```
Exit w3m using "Q" and check the contents of output.txt. An OpenBao token should be displayed proving that authentication was successful.

```
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
token_meta_role      oidc-user
```

## Stop the Example
```
make down
```