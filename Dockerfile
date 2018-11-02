FROM registry.xe2/debian:stretch-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openconnect \
    openssh-server \
    iputils-ping \
    iputils-tracepath \
    dnsutils \
    jq \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY mototunnel vpn_login.sh vpn_uptime /

CMD ["/mototunnel"]
