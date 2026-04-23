#!/bin/sh

while ! [ -f /certs/spire-agent.pem ]; do
    echo "Waiting for client certificate to be generated..."
    sleep 2
done

exec spire-agent run -config /opt/spire/config/spire-agent.conf