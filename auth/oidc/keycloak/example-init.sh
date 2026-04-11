#!/usr/bin/env sh

# Wait for Keycloak to be ready.
kc_ready=1

until [ "$kc_ready" -eq 0 ]; do
  echo "Waiting for Keycloak to be ready..."

  curl --head --connect-timeout 1 --max-time 5 http://keycloak:9000/health/ready > /dev/null 2>&1
  kc_ready="$?"

  sleep 5
done

echo "Keycloak ready..."

# Configure Keycloak.
echo "Obtaining Keycloak admin token..."
KC_TOKEN=$(curl -sf \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=${KC_BOOTSTRAP_ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  "http://keycloak:8080/realms/master/protocol/openid-connect/token" \
  | jq -r '.access_token')

REALM="openbao-demo"
echo "Creating realm '${REALM}'..."
curl -sf \
  -X POST \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"realm\": \"${REALM}\",
    \"displayName\": \"Demo Realm\",
    \"enabled\": true
  }" \
  "http://keycloak:8080/admin/realms"

CLIENT_ID="openbao"
echo "Creating client '${CLIENT_ID}'..."
curl -sf \
  -X POST \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"${CLIENT_ID}\",
    \"enabled\": true,
    \"publicClient\": false,
    \"standardFlowEnabled\": true,
    \"redirectUris\": [\"http://localhost:8250/oidc/callback\"]
  }" \
  "http://keycloak:8080/admin/realms/${REALM}/clients"

CLIENT_UUID=$(curl -sf \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  "http://keycloak:8080/admin/realms/${REALM}/clients?clientId=${CLIENT_ID}" \
  | jq -r '.[0].id')

CLIENT_SECRET=$(curl -sf \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  "http://keycloak:8080/admin/realms/${REALM}/clients/${CLIENT_UUID}/client-secret" \
  | jq -r '.value')

echo "Creating user 'oidc-user'..."
curl -sf \
  -X POST \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"oidc-user\",
    \"email\": \"oidc-user@example.com\",
    \"firstName\": \"Demo\",
    \"lastName\": \"User\",
    \"enabled\": true,
    \"credentials\": [{
      \"type\": \"password\",
      \"value\": \"${OIDC_USER_PASSWORD}\",
      \"temporary\": false
    }]
  }" \
  "http://keycloak:8080/admin/realms/${REALM}/users"

echo "User 'oidc-user' created."

# Configure OpenBao
bao auth enable oidc
bao write auth/oidc/config \
  oidc_client_id="${CLIENT_ID}" \
  oidc_client_secret="${CLIENT_SECRET}" \
  default_role="oidc-user" \
  oidc_discovery_url="http://keycloak:8080/realms/${REALM}"

bao write auth/oidc/role/oidc-user \
  role_type="oidc" \
  user_claim="sub" \
  policies="default" \
  oidc_scopes="profile,email" \
  allowed_redirect_uris="http://vault:8200/v1/auth/oidc/callback,https://vault:8200/ui/vault/auth/oidc/oidc/callback,http://localhost:8250/oidc/callback"

echo ""
echo ""
echo "Example ready! You can now log in to OpenBao using 'bao login -method=oidc' and the 'oidc-user' account with the password set in the OIDC_USER_PASSWORD environment variable."

sleep infinity