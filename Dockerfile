#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="1.0.0"
ARG plugins="git,cloudflare,dnspod,cors,realip,expires,cache"
ARG enable_telemetry="false"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.10
LABEL maintainer "Abiola Ibrahim <abiola89@gmail.com>"

ARG version="1.0.3"
LABEL caddy_version="$version"

# PHP www-user UID and GID
ARG PUID="1000"
ARG PGID="1000"

# Let's Encrypt Agreement
ENV ACME_AGREE="true"

# Telemetry Stats
ENV ENABLE_TELEMETRY="$enable_telemetry"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]

