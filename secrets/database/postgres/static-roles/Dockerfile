FROM openbao/openbao:latest as openbao

RUN apk --no-cache update \
    && apk --no-cache add \
    postgresql-client \
    curl \
    jq