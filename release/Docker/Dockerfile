FROM alpine:latest
RUN apk add --no-cache curl && \
    curl -OL 'https://github.com/filiparag/hetzner_ddns/releases/download/1.0.1/hetzner_ddns-1.0.1-alpinelinux.apk' && \
    apk add --no-interactive --allow-untrusted ./hetzner_ddns-1.0.1-alpinelinux.apk && \
    rm -f ./hetzner_ddns-1.0.1-alpinelinux.apk
ENTRYPOINT ["hetzner_ddns", "-V"]
