FROM alpine:latest

RUN apk add --no-cache \
    supervisor \
    openssl \
    curl \
    tar \
    jq

RUN adduser -u 10000 -H -D spire

RUN mkdir -p /opt/spire/bin \
    /opt/spire/config \
    /opt/spire/data

RUN curl -L -o /tmp/spire-1.14.5-linux-amd64-musl.tar.gz https://github.com/spiffe/spire/releases/download/v1.14.5/spire-1.14.5-linux-amd64-musl.tar.gz \
    && tar -xzf /tmp/spire-1.14.5-linux-amd64-musl.tar.gz -C /opt/spire/bin spire-1.14.5/bin/spire-server --strip-components=2 \
    && rm /tmp/spire-1.14.5-linux-amd64-musl.tar.gz

RUN curl -L -o /tmp/spire-extras-1.14.5-linux-amd64-musl.tar.gz https://github.com/spiffe/spire/releases/download/v1.14.5/spire-extras-1.14.5-linux-amd64-musl.tar.gz \
    && tar -xzf /tmp/spire-extras-1.14.5-linux-amd64-musl.tar.gz -C /opt/spire/bin spire-extras-1.14.5/bin/oidc-discovery-provider --strip-components=2 \
    && rm /tmp/spire-extras-1.14.5-linux-amd64-musl.tar.gz

RUN ln -sf /opt/spire/bin/spire-server /usr/local/bin/spire-server
RUN ln -sf /opt/spire/bin/oidc-discovery-provider /usr/local/bin/oidc-discovery-provider

COPY start-spire-server.sh /usr/local/bin/start-spire-server.sh
RUN chmod +x /usr/local/bin/start-spire-server.sh

COPY create-certs.sh /usr/local/bin/create-certs.sh
RUN chmod +x /usr/local/bin/create-certs.sh

COPY supervisord.conf /etc/supervisord.conf
COPY spire-server.conf /opt/spire/config/spire-server.conf
COPY oidc-discovery-provider.conf /opt/spire/config/oidc-discovery-provider.conf

RUN chown -R spire:spire /opt/spire

CMD ["supervisord", "-c", "/etc/supervisord.conf"]