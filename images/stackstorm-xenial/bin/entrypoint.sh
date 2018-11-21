#!/bin/bash

set -e

# Create htpasswd file and login to st2 using specified username/password
htpasswd -b /etc/st2/htpasswd ${ST2_USER} ${ST2_PASSWORD}

mkdir -p /root/.st2

ROOT_CONF=/root/.st2/config

touch ${ROOT_CONF}

crudini --set ${ROOT_CONF} credentials username ${ST2_USER}
crudini --set ${ROOT_CONF} credentials password ${ST2_PASSWORD}

ST2_CONF=/etc/st2/st2.conf

ST2_API_URL=${ST2_API_URL:-http://127.0.0.1:9101}
MISTRAL_BASE_URL=${MISTRAL_BASE_URL:-http://127.0.0.1:8989/v2}

crudini --set ${ST2_CONF} auth api_url ${ST2_API_URL}
crudini --set ${ST2_CONF} mistral api_url ${ST2_API_URL}
crudini --set ${ST2_CONF} mistral v2_base_url ${MISTRAL_BASE_URL}
crudini --set ${ST2_CONF} messaging url \
  amqp://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}
crudini --set ${ST2_CONF} coordination url \
  redis://:${REDIS_PASSWORD}@${REDIS_HOST}:${REDIS_PORT}
crudini --set ${ST2_CONF} database host ${MONGO_HOST}
crudini --set ${ST2_CONF} database port ${MONGO_PORT}
if [ ! -z ${MONGO_DB} ]; then
  crudini --set ${ST2_CONF} database db_name ${MONGO_DB}
fi
if [ ! -z ${MONGO_USER} ]; then
  crudini --set ${ST2_CONF} database username ${MONGO_USER}
fi
if [ ! -z ${MONGO_PASS} ]; then
  crudini --set ${ST2_CONF} database password ${MONGO_PASS}
fi

# NOTE: Only certain distros of MongoDB support SSL/TLS
#  1) enterprise versions
#  2) those built from source (https://github.com/mongodb/mongo/wiki/Build-Mongodb-From-Source)
#
#crudini --set ${ST2_CONF} database ssl True
#crudini --set ${ST2_CONF} database ssl_keyfile None
#crudini --set ${ST2_CONF} database ssl_certfile None
#crudini --set ${ST2_CONF} database ssl_cert_reqs None
#crudini --set ${ST2_CONF} database ssl_ca_certs None
#crudini --set ${ST2_CONF} database ssl_match_hostname True


if [ -z ${ST2_DISABLE_MISTRAL} ]; then
  MISTRAL_CONF=/etc/mistral/mistral.conf

  crudini --set ${MISTRAL_CONF} DEFAULT transport_url \
    rabbit://${RABBITMQ_DEFAULT_USER}:${RABBITMQ_DEFAULT_PASS}@${RABBITMQ_HOST}:${RABBITMQ_PORT}
  crudini --set ${MISTRAL_CONF} database connection \
    postgresql+psycopg2://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
fi

# Set default variables for all components
export ST2API_DAEMON_ARGS="-k eventlet -b 127.0.0.1:9101 --workers 1 --threads 1 --graceful-timeout 10 --timeout 30 --log-config /etc/st2/logging.api.gunicorn.conf"
export ST2AUTH_DAEMON_ARGS="-k eventlet -b 127.0.0.1:9100 --workers 1 --threads 1 --graceful-timeout 10 --timeout 30 --log-config /etc/st2/logging.auth.gunicorn.conf"
export ST2STREAM_DAEMON_ARGS="-k eventlet -b 127.0.0.1:9102 --workers 1 --threads 10 --graceful-timeout 10 --timeout 30 --log-config /etc/st2/logging.stream.gunicorn.conf"
export ST2SENSORCONTAINER_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2RULESENGINE_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2TIMERSENGINE_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2WORKFLOWENGINE_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2ACTIONRUNNER_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2NOTIFIER_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2GARBAGECOLLECTOR_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2SCHEDULER_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
export ST2CHATOPS_DAEMON_ARGS=""


if [ -z ${ST2_DISABLE_MISTRAL} ]; then
  export ST2RESULTSTRACKER_DAEMON_ARGS="--config-file /etc/st2/st2.conf"
  export MISTRAL_API_ARGS="--log-file /var/log/mistral/mistral-api.log -b 127.0.0.1:8989 -w 2 mistral.api.wsgi --graceful-timeout 10"
  export MISTRAL_SERVER_ARGS="--config-file /etc/mistral/mistral.conf --log-file /var/log/mistral/mistral-server.log"

  cp /st2-docker/supervisord.d/st2mistral.conf /etc/supervisor/conf.d
fi


if [ ! -z ${ST2_ENABLE_SSHD} ]; then
  cp /st2-docker/supervisord.d/sshd.conf /etc/supervisor/conf.d
fi

# Run custom init scripts
for f in /st2-docker/entrypoint.d/*; do
  case "$f" in
    *.sh) echo "$0: running $f"; . "$f" ;;
    *)    echo "$0: ignoring $f" ;;
  esac
  echo
done

# 1ppc: launch entrypoint-1ppc.sh via dumb-init if $ST2_SERVICE is set
if [ ! -z ${ST2_SERVICE} ]; then
  exec /dumb-init -- /st2-docker/bin/entrypoint-1ppc.sh
fi

if [ -z ${ST2_DISABLE_MISTRAL} ]; then
  /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf upgrade head
  /opt/stackstorm/mistral/bin/mistral-db-manage --config-file /etc/mistral/mistral.conf populate
fi

# launch supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
