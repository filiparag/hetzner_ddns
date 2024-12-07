FROM alpine:latest
RUN apk add --no-cache curl && \
    curl -OL 'https://github.com/filiparag/hetzner_ddns/releases/download/0.2.6/hetzner_ddns-0.2.6-alpinelinux.apk' && \
    apk add --no-interactive --allow-untrusted ./hetzner_ddns-0.2.6-alpinelinux.apk && \
    rm -f ./hetzner_ddns-0.2.6-alpinelinux.apk
ENTRYPOINT ["hetzner_ddns"]
