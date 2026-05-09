# JWT Authentication using SPIRE

[SPIFFE and SPIRE](https://spiffe.io) can provide cryptographic identities to workloads across a wide variety of platforms in the form of [SPIFFE Verifiable Identity Documents (SVIDs)](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#spiffe-verifiable-identity-document-svid). In this example we'll take a look at how a [JWT SVID](https://spiffe.io/docs/latest/spiffe-specs/jwt-svid/) issued by SPIRE can be used to authenticate to OpenBao.

1. [Start the Example](#start-the-example)
1. [SPIRE Configuration](#spire-configuration)
1. [OpenBao Configuration](#openbao-configuration)
1. [Retrieving a JWT and Logging Into OpenBao](#retrieving-a-jwt-and-logging-into-openbao)
1. [Stop the Example](#stop-the-example)

# Start the Example
1.  The example can be started as shown below.
    ```bash
    make up
    ```

Once this completes there will be three containers running:

- **openbao** - The OpenBao server.
- **spire-server** - The SPIRE server and OIDC provider.
- **spire-agent** - The SPIRE agent.

# SPIRE Configuration
1.  Exec into the spire-server container using `make exec-spire-server`. List the attested agents.
    ```bash
    spire-server agent list
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Found 1 attested agent:
    SPIFFE ID         : spiffe://home.arpa/spire/agent/x509pop/f26ae83e62c22e36d3f56c2e8ceb71981c699d5d
    Attestation type  : x509pop
    Expiration time   : 2026-04-23 02:14:40 +0000 UTC
    Serial number     : 304763988453627038836466069795370675073
    Can re-attest     : true
    Agent version     : 1.14.5</pre>
    </details>

1.  Using the SPIFFE ID of the agent as the parent ID, create a registration entry for "workload-1". SPIRE supports many selectors but in this case we'll use a simple selector based on a user ID of `10001`.
    ```bash
    spiffe_path=$(spire-server agent list --output=json | jq -r .agents[0].id.path)
    spiffe_parent_id="spiffe://home.arpa${spiffe_path}"
    
    spire-server entry create -parentID "$spiffe_parent_id" \
    -spiffeID spiffe://home.arpa/workload-1 -selector unix:uid:10001
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Entry ID         : 22ba28ec-9f54-448a-a4fc-1f823cc5e6a1
    SPIFFE ID        : spiffe://home.arpa/workload-1
    Parent ID        : spiffe://home.arpa/spire/agent/x509pop/f26ae83e62c22e36d3f56c2e8ceb71981c699d5d
    Revision         : 0
    X509-SVID TTL    : default
    JWT-SVID TTL     : default
    Selector         : unix:uid:10001</pre>
    </details>

1.  Exit the `spire-server` container.

# OpenBao Configuration
1.  Exec into the openbao container using `make exec-openbao` and enable the JWT authentication method.
    ```bash
    bao auth enable jwt
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Enabled jwt auth method at: jwt/</pre>
    </details>

1. Configure the JWT authentication method with an `oidc_discovery_url` pointing to the OIDC discovery provider running alongside the SPIRE server.
    ```bash
    bao write auth/jwt/config \
        oidc_discovery_url=http://spire-server:8080
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/jwt/config</pre>
    </details>

1.  Create a JWT role. The `user_claim` and `bound_subject` fields allow OpenBao to verify the identity of the client attempting to authenticate.
    ```bash
    bao write auth/jwt/role/workload-1 \
        role_type="jwt" \
        bound_audiences="openbao" \
        user_claim="sub" \
        bound_subject="spiffe://home.arpa/workload-1" \
        token_policies=workload-1-policy \
        token_ttl="1h"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Success! Data written to: auth/jwt/role/workload-1</pre>
    </details>

1.  Exit the `openbao` container.

# Retrieving a JWT and Logging Into OpenBao
1.  Exec into the spire-agent container using `make exec-spire-agent`. The spire-agent itself can be used to test retrieving a JWT from the workload API. Change to the `workload-1` user using `su - workload-1`. The UID of this user is 10001 matching the entry created earlier for SPIFFE ID `spiffe://home.arpa/workload-1`.
    ```bash
    export BAO_ADDR=http://openbao:8200
    spire-agent api fetch jwt -audience openbao
    ```
    <details>
    <summary>Sample output</summary>
    <pre>token(spiffe://home.arpa/workload-1):
    eyJhbGciOiJFUzI1NiIsImtpZCI6IkJUMGZid0xnQ2RZMW9PYzdTYTNzN3pEVFNEbDFobGhTIiwidHlwIjoiSldUIn0.eyJhdWQiOlsib3BlbmJhbyJdLCJleHAiOjE3NzgyOTU4NDksImlhdCI6MTc3ODI5NTU0OSwic3ViIjoic3BpZmZlOi8vaG9tZS5hcnBhL3dvcmtsb2FkLTEifQ.SbojmoTDpNjyTG_y86f00eNlBLKeSDOkntBMhCvPIbM8lEfzeTL0bHqhd47-acKXCXInrsr7RF9rneAD7GxHzw
    bundle(spiffe://home.arpa):
        {
    "keys": [
        {
            "kty": "EC",
            "kid": "BT0fbwLgCdY1oOc7Sa3s7zDTSDl1hlhS",
            "crv": "P-256",
            "x": "-_ghqWgTdmB3V7W9u1b_HhXigzNVNOyQQM0vd2BgfKk",
            "y": "dyRTuaAvF-OZpXMWbagd-CLhkK3WzITU_cIqEJFeKI8"
        }
    ]
    }</pre>
    </details>

1.  After a JWT has been retrieved it can be used to authenticate to OpenBao.
    ```bash
    jwt=$(spire-agent api fetch jwt -audience openbao -output=json | jq -r '.[0].svids.[0].svid')
    bao write auth/jwt/login role='workload-1' jwt="$jwt"
    ```
    <details>
    <summary>Sample output</summary>
    <pre>Key                  Value
    ---                  -----
    token                s.eSyds1qR0669Mi5kXzgz3c4g
    token_accessor       Xt8AlyHLBJlBoexiekrmKvS6
    token_duration       768h
    token_renewable      true
    token_policies       ["default" "workload-1-policy"]
    identity_policies    []
    policies             ["default" "workload-1-policy"]
    token_meta_role      workload-1</pre>
    </details>

1.  Exit the `spire-agent` container.

# Stop the Example
```
make down
```