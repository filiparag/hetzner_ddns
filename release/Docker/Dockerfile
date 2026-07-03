FROM dhi.io/alpine-base:3.23-dev
RUN apk add --no-cache curl && \
    curl -OL 'https://github.com/filiparag/hetzner_ddns/releases/download/1.1.0/hetzner_ddns-1.1.0-alpinelinux.apk' && \
    apk add --no-interactive --allow-untrusted ./hetzner_ddns-1.1.0-alpinelinux.apk && \
    rm -f ./hetzner_ddns-1.1.0-alpinelinux.apk
ENTRYPOINT ["hetzner_ddns", "-V"]
