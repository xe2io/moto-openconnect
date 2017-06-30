FROM debian:stretch-slim
# apt caching!  Remove when done
RUN  echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy


RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    openconnect \
    ocproxy \
    openssh-server \
    iputils-ping \
    iputils-tracepath \
    dnsutils \
	--no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*

COPY mototunnel vpn_uptime /

# Remove the apt proxy
#RUN rm /etc/apt/apt.conf.d/01proxy

CMD ["/mototunnel"]