FROM golang:1.24-bookworm as builder

ADD . /webtunnel

ENV CGO_ENABLED=0

WORKDIR /webtunnel

RUN go build -ldflags="-s -w" -o "build/server" gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/webtunnel/main/server

FROM containers.torproject.org/tpo/tpa/base-images/debian:bookworm

COPY --from=builder /webtunnel/build/server /usr/bin/webtunnel-server

# Install dependencies to add Tor's repository.
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    gpg \
    gpg-agent \
    ca-certificates \
    libcap2-bin \
    --no-install-recommends

# See: <https://2019.www.torproject.org/docs/debian.html.en>
RUN curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
RUN gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

RUN groupadd -g 101 debian-tor
RUN useradd --system -u 101 -g 101 -s /usr/bin/nologin -d /var/lib/tor debian-tor

RUN printf "deb https://deb.torproject.org/torproject.org bookworm main\n" >> /etc/apt/sources.list.d/tor.list

# Install remaining dependencies.
RUN apt-get update && apt-get install -y \
    tor \
    tor-geoipdb \
    --no-install-recommends

# Our torrc is generated at run-time by the script start-tor.sh.
RUN rm /etc/tor/torrc
RUN chown debian-tor:debian-tor /etc/tor
RUN chown debian-tor:debian-tor /var/log/tor

ADD release/container/start-tor.sh /usr/local/bin
RUN chmod 0755 /usr/local/bin/start-tor.sh

# !!! This is a sudo setuid binary, CHANGE IT WITH CAUTION.
ADD release/container/chown-states.sh /usr/local/bin
RUN chmod 0755 /usr/local/bin/chown-states.sh
RUN echo "debian-tor ALL=(ALL) NOPASSWD: sha256:43f867a3d7e57679d64452beae97c5f9a4b0b314a89f38d57b0a183a6e3abfb6 /usr/local/bin/chown-states.sh" > /etc/sudoers.d/allow-chown-volume

ADD release/container/get-bridge-line.sh /usr/local/bin
RUN chmod 0755 /usr/local/bin/get-bridge-line.sh

ENTRYPOINT ["/usr/local/bin/start-tor.sh"]
