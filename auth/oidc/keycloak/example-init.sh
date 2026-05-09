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
  -d "password=admin" \
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
CLIENT_SECRET="openbao"
echo "Creating client '${CLIENT_ID}'..."
curl -sf \
  -X POST \
  -H "Authorization: Bearer ${KC_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"${CLIENT_ID}\",
    \"secret\": \"${CLIENT_SECRET}\",
    \"enabled\": true,
    \"publicClient\": false,
    \"standardFlowEnabled\": true,
    \"redirectUris\": [\"http://localhost:8250/oidc/callback\"]
  }" \
  "http://keycloak:8080/admin/realms/${REALM}/clients"

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
      \"value\": \"password123\",
      \"temporary\": false
    }]
  }" \
  "http://keycloak:8080/admin/realms/${REALM}/users"


sleep infinity