FROM debian:stretch-slim
# apt caching!  Remove when done
RUN  echo 'Acquire::http { Proxy "http://heatsink.xe2:3142"; };' >> /etc/apt/apt.conf.d/01proxy


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

# Remove the apt proxy
#RUN rm /etc/apt/apt.conf.d/01proxy

CMD ["/mototunnel"]
