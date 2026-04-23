# JWT Authentication using SPIRE

[SPIFFE and SPIRE](https://spiffe.io) can provide cryptographic identities to workloads across a wide variety of platforms in the form of [SPIFFE Verifiable Identity Documents (SVIDs)](https://spiffe.io/docs/latest/spiffe-about/spiffe-concepts/#spiffe-verifiable-identity-document-svid). In this example we'll take a look at how a [JWT SVID](https://spiffe.io/docs/latest/spiffe-specs/jwt-svid/) issued by SPIRE can be used to authenticate to OpenBao.

# Overview

In the steps below, we'll retrieve a JWT from the SPIRE agent's workload API and use it to authenticate to OpenBao. To do this we'll:

1. Create registration entries on the SPIRE server to identify our workload
1. Configure OpenBao with a JWT authentication method and roles which can be used to log in
1. Retrieve a JWT from the SPIRE agent workload API and use it to authenticate to OpenBao

# Steps

The example can be started as shown below.
```
make up
```

Once this completes there will be three containers running:

- **openbao** - The OpenBao server.
- **spire-server** - The SPIRE server and OIDC provider.
- **spire-agent** - The SPIRE agent. This has been automatically registered with the SPIRE server.

## SPIRE Configuration
Exec into the spire-server container using `make exec-spire-server`. Running `spire-server agent list` should show that a SPIRE agent has been registered.
```
Found 1 attested agent:

SPIFFE ID         : spiffe://home.arpa/spire/agent/x509pop/f26ae83e62c22e36d3f56c2e8ceb71981c699d5d
Attestation type  : x509pop
Expiration time   : 2026-04-23 02:14:40 +0000 UTC
Serial number     : 304763988453627038836466069795370675073
Can re-attest     : true
Agent version     : 1.14.5
```

Using the SPIFFE ID of the agent as the parent ID, create two registration entries, one for "workload-1" and the other for "workload-2". SPIRE supports many selectors but in this case we'll use a simple selector based on the user ID of a process.
```
spiffe_path=$(spire-server agent list --output=json | jq -r .agents[0].id.path)
spiffe_parent_id="spiffe://home.arpa${spiffe_path}"

spire-server entry create -parentID "$spiffe_parent_id" \
    -spiffeID spiffe://home.arpa/workload-1 -selector unix:uid:10001

spire-server entry create -parentID "$spiffe_parent_id" \
    -spiffeID spiffe://home.arpa/workload-2 -selector unix:uid:10002
```

## OpenBao Configuration
Exec into the openbao container using `make exec-openbao`. First, we'll create two kv secrets, one for each of our workloads and two policies that allow access to the secrets.

```
bao kv put secret/workload-1/api-key key=foo
bao kv put secret/workload-2/api-key key=bar

bao policy write workload-1-policy - <<EOF
path "secret/data/workload-1/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}

path "secret/metadata/workload-1/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}
EOF

bao policy write workload-2-policy - <<EOF
path "secret/data/workload-2/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}

path "secret/metadata/workload-2/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}
EOF
```

Next, we'll enable and configure a JWT authentication method. The "oidc_discovery_url" points to the OIDC discovery provider running alongside the SPIRE server. We'll also create two roles, the "user_claim" and "bound_subject" fields allow OpenBao to verify the identity of the client attempting to authenticate.
```
bao auth enable jwt

bao write auth/jwt/config \
    oidc_discovery_url=http://spire-server:8080

bao write auth/jwt/role/workload-1 \
    role_type="jwt" \
    bound_audiences="openbao" \
    user_claim="sub" \
    bound_subject="spiffe://home.arpa/workload-1" \
    token_policies=workload-1-policy \
    token_ttl="1h"

bao write auth/jwt/role/workload-2 \
    role_type="jwt" \
    bound_audiences="openbao" \
    user_claim="sub" \
    bound_subject="spiffe://home.arpa/workload-2" \
    token_policies=workload-2-policy \
    token_ttl="1h"
```

## Retrieving a JWT and Logging Into OpenBao
Exec into the spire-agent container using `make exec-spire-agent`. The spire-agent itself can be used to test with. Change to the "workload-1" user using `su - workload-1`. The UID of this user is 10001 matching the entry created earlier for SPIFFE ID "spiffe://home.arpa/workload-1".
```
export BAO_ADDR=http://openbao:8200

jwt=$(spire-agent api fetch jwt -audience openbao -output=json | jq -r '.[0].svids.[0].svid')
bao write auth/jwt/login role='workload-1' jwt="$jwt"
```
If authentication was successful, an OpenBao token will be returned.
```
Key                  Value
---                  -----
token                s.eSyds1qR0669Mi5kXzgz3c4g
token_accessor       Xt8AlyHLBJlBoexiekrmKvS6
token_duration       768h
token_renewable      true
token_policies       ["default" "workload-1-policy"]
identity_policies    []
policies             ["default" "workload-1-policy"]
token_meta_role      workload-1
```

## Stop the Example
```
make down
```