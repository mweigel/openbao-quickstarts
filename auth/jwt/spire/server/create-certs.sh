#!/bin/sh

cd /certs && rm -f *.pem

openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -keyout ca-key.pem -out ca.pem \
  -subj "/CN=OpenBao Quickstarts/O=Testing/C=NZ"

openssl req -new -newkey rsa:2048 -nodes \
  -keyout spire-agent-key.pem -out spire-agent.pem \
  -subj "/CN=Spire Agent/O=Testing" \
  -addext "keyUsage = critical, digitalSignature, keyEncipherment" \
  -addext "extendedKeyUsage = clientAuth" \
  -addext "subjectAltName = URI:spiffe://home.arpa/spire-agent" \
  -x509 -CA ca.pem -CAkey ca-key.pem -days 365

chown spire:spire *