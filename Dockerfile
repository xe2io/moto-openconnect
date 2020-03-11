FROM r.xe2.io/debian:buster-slim

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

COPY mototunnel vpn_login.sh /

CMD ["/mototunnel"]
