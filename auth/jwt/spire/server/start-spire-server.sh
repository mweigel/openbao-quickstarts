#!/bin/sh

while ! [ -f /certs/ca.pem ]; do
    echo "Waiting for CA certificate to be generated..."
    sleep 2
done

exec spire-server run -config /opt/spire/config/spire-server.conf