FROM alpine:latest
RUN apk add --no-cache curl && \
    curl -OL 'https://github.com/filiparag/hetzner_ddns/releases/download/0.2.4/hetzner_ddns-0.2.4.apk' && \
    apk add --no-interactive --allow-untrusted ./hetzner_ddns-0.2.4.apk && \
    rm -f ./hetzner_ddns-0.2.4.apk
ENTRYPOINT ["hetzner_ddns"]
