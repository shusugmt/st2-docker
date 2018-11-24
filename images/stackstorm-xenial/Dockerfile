# syntax = tonistiigi/dockerfile:runmount20180618

FROM ubuntu:16.04

ARG ST2_REPO=stable
ARG ST2_VERSION
ARG NODE_REPO=node_6.x

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
#
apt update && \
apt -y install curl gnupg apt-transport-https && \
# st2 repo
curl -sSL https://packagecloud.io/StackStorm/${ST2_REPO}/gpgkey | apt-key add - && \
echo "deb https://packagecloud.io/StackStorm/${ST2_REPO}/ubuntu/ xenial main" > /etc/apt/sources.list.d/st2.list && \
# nodejs repo
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
echo "deb https://deb.nodesource.com/${NODE_REPO} xenial main" > /etc/apt/sources.list.d/nodesource.list && \
# nginx repo
curl -sSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list && \
#
apt update

RUN \
--mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
# 
apt -y install \
 st2=${ST2_VERSION}* \
 st2web=${ST2_VERSION}* \
 st2chatops=${ST2_VERSION}* \
 st2mistral=${ST2_VERSION}* \
 supervisor \
 crudini \
 apache2-utils \
 locales \
 nginx \
 uuid-runtime

RUN cp /usr/share/doc/st2/conf/nginx/st2.conf /etc/nginx/conf.d/st2.conf

# Install redis client library for coordination backend
# see: https://docs.stackstorm.com/latest/reference/policies.html
RUN bash -c 'source /opt/stackstorm/st2/bin/activate && pip install redis'

COPY ${ST2_REPO}/supervisord.conf /etc/supervisor/supervisord.conf

COPY bin/entrypoint.sh /st2-docker/bin/entrypoint.sh
COPY bin/entrypoint-1ppc.sh /st2-docker/bin/entrypoint-1ppc.sh
COPY bin/run-postinit.sh /st2-docker/bin/run-postinit.sh
COPY bin/run-sshd.sh /st2-docker/bin/run-sshd.sh

COPY supervisord.d/st2mistral.conf /st2-docker/supervisord.d/st2mistral.conf
COPY supervisord.d/sshd.conf /st2-docker/supervisord.d/sshd.conf

COPY st2ctl /opt/stackstorm/st2/bin/st2ctl

COPY insecure_keys/insecure_datastore_key.json /etc/st2/keys/datastore_key.json 
COPY insecure_keys/insecure_ssl_st2.crt /etc/ssl/st2/st2.crt
COPY insecure_keys/insecure_ssl_st2.key /etc/ssl/st2/st2.key
RUN chgrp -Rf st2 /etc/st2/keys \
 && chmod -Rf o-r /etc/st2/keys \
 && chgrp -Rf st2 /etc/ssl/st2 \
 && chmod -Rf o-r /etc/ssl/st2

RUN crudini --set /etc/st2/st2.conf auth enable True \
 && crudini --set /etc/st2/st2.conf keyvalue encryption_key_path /etc/st2/keys/datastore_key.json

# should be done on top
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ENTRYPOINT ["/st2-docker/bin/entrypoint.sh"]
