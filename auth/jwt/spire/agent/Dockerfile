FROM openbao/openbao:latest

RUN apk add --no-cache \
    openssl \
    curl \
    tar \
    jq

RUN adduser -u 10000 -H -D spire

RUN mkdir -p /opt/spire/bin \
    /opt/spire/config \
    /opt/spire/data

RUN curl -L -o /tmp/spire-1.14.5-linux-amd64-musl.tar.gz https://github.com/spiffe/spire/releases/download/v1.14.5/spire-1.14.5-linux-amd64-musl.tar.gz \
    && tar -xzf /tmp/spire-1.14.5-linux-amd64-musl.tar.gz -C /opt/spire/bin spire-1.14.5/bin/spire-agent --strip-components=2 \
    && rm /tmp/spire-1.14.5-linux-amd64-musl.tar.gz

RUN ln -sf /opt/spire/bin/spire-agent /usr/local/bin/spire-agent

COPY start-spire-agent.sh /usr/local/bin/start-spire-agent.sh
RUN chmod +x /usr/local/bin/start-spire-agent.sh

COPY spire-agent.conf /opt/spire/config/spire-agent.conf

RUN chown -R spire:spire /opt/spire

RUN adduser -u 10001 -D workload-1
RUN adduser -u 10002 -D workload-2

ENTRYPOINT ["/usr/local/bin/start-spire-agent.sh"]