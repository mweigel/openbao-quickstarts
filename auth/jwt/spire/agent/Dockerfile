FROM openbao/openbao:latest

ARG TARGETARCH
ARG SPIRE_VERSION=1.14.5
ARG SPIRE_PACKAGE=spire-${SPIRE_VERSION}-linux-${TARGETARCH}-musl.tar.gz

RUN apk add --no-cache \
    openssl \
    curl \
    tar \
    jq

RUN adduser -u 10000 -H -D spire

RUN mkdir -p /opt/spire/bin \
    /opt/spire/config \
    /opt/spire/data

RUN curl -L -o /tmp/${SPIRE_PACKAGE} https://github.com/spiffe/spire/releases/download/v${SPIRE_VERSION}/${SPIRE_PACKAGE} \
    && tar -xzf /tmp/${SPIRE_PACKAGE} -C /opt/spire/bin spire-${SPIRE_VERSION}/bin/spire-agent --strip-components=2 \
    && rm /tmp/${SPIRE_PACKAGE}

RUN ln -sf /opt/spire/bin/spire-agent /usr/local/bin/spire-agent

COPY start-spire-agent.sh /usr/local/bin/start-spire-agent.sh
RUN chmod +x /usr/local/bin/start-spire-agent.sh

COPY spire-agent.conf /opt/spire/config/spire-agent.conf

RUN chown -R spire:spire /opt/spire

RUN adduser -u 10001 -D workload-1

ENTRYPOINT ["/usr/local/bin/start-spire-agent.sh"]
