FROM alpine:latest
RUN apk add --no-cache curl && \
    curl -OL 'https://github.com/filiparag/hetzner_ddns/releases/download/0.2.5/hetzner_ddns-0.2.5.apk' && \
    apk add --no-interactive --allow-untrusted ./hetzner_ddns-0.2.5.apk && \
    rm -f ./hetzner_ddns-0.2.5.apk
ENTRYPOINT ["hetzner_ddns"]
