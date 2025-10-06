# Build based on redis:7.2.5 from "2024-05-22T23:17:59Z"
# FROM redis@sha256:e422889e156ebea83856b6ff973bfe0c86bce867d80def228044eeecf925592b

# Build based on arm64 redis:7.2.5:
# https://hub.docker.com/layers/library/redis/7.2.5/images/sha256-48f4dde7f0231a8138727a73b32ecf65ac3c2138fdf3c654c5495eb368214a5b
FROM redis@sha256:3aaec283e6e593bde528077d60280ac1589887067a39273348860837c9346d7e

# LABEL maintainer="Johan Andersson <Grokzen@gmail.com>"

# Some Environment Variables
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install system dependencies
RUN apt-get update -qq && \
    apt install -y --reinstall ca-certificates && \
    update-ca-certificates && \
    apt-get install --no-install-recommends -yqq \
      net-tools supervisor ruby rubygems locales gettext-base wget gcc make g++ build-essential libc6-dev tcl pkg-config && \
    apt-get clean -yqq

# # Ensure UTF-8 lang and locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Necessary for gem installs due to SHA1 being weak and old cert being revoked
ENV SSL_CERT_FILE=/usr/local/etc/openssl/cert.pem

RUN gem install redis -v 4.1.3

# This will always build the latest release/commit in the 7.2 branch
ARG redis_version=7.2

RUN wget -qO redis.tar.gz https://github.com/redis/redis/tarball/${redis_version} \
    && tar xfz redis.tar.gz -C / \
    && mv /redis-* /redis

RUN (cd /redis && make)

RUN mkdir /redis-conf && mkdir /redis-data

COPY redis-cluster.tmpl /redis-conf/redis-cluster.tmpl
COPY redis.tmpl         /redis-conf/redis.tmpl
COPY sentinel.tmpl      /redis-conf/sentinel.tmpl

# Add startup script
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Add script that generates supervisor conf file based on environment variables
COPY generate-supervisor-conf.sh /generate-supervisor-conf.sh

RUN chmod 755 /docker-entrypoint.sh

EXPOSE 7000 7001 7002 7003 7004 7005 7006 7007 5000 5001 5002

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["redis-cluster"]
