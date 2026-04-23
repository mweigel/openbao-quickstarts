FROM alpine:latest

ARG TARGETARCH
ARG SPIRE_VERSION=1.14.5
ARG SPIRE_PACKAGE=spire-${SPIRE_VERSION}-linux-${TARGETARCH}-musl.tar.gz
ARG SPIRE_EXTRAS_PACKAGE=spire-extras-${SPIRE_VERSION}-linux-${TARGETARCH}-musl.tar.gz

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

RUN curl -L -o /tmp/${SPIRE_PACKAGE} https://github.com/spiffe/spire/releases/download/v${SPIRE_VERSION}/${SPIRE_PACKAGE} \
    && tar -xzf /tmp/${SPIRE_PACKAGE} -C /opt/spire/bin spire-${SPIRE_VERSION}/bin/spire-server --strip-components=2 \
    && rm /tmp/${SPIRE_PACKAGE}

RUN curl -L -o /tmp/${SPIRE_EXTRAS_PACKAGE} https://github.com/spiffe/spire/releases/download/v1.14.5/${SPIRE_EXTRAS_PACKAGE} \
    && tar -xzf /tmp/${SPIRE_EXTRAS_PACKAGE} -C /opt/spire/bin spire-extras-1.14.5/bin/oidc-discovery-provider --strip-components=2 \
    && rm /tmp/${SPIRE_EXTRAS_PACKAGE}

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