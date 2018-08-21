#!/bin/bash

LOG_SIZE_MAX="50*1024*1024"

/opt/stackstorm/mistral/bin/pip install djehouty

cat << EOF > /etc/mistral/logging-gelf.conf
[loggers]
keys=root

[handlers]
keys=gelfHandler

[formatters]
keys=gelfFormatter

[logger_root]
level=INFO
handlers=gelfHandler

[handler_gelfHandler]
class=handlers.RotatingFileHandler
level=DEBUG
formatter=gelfFormatter
args=("/var/log/mistral/mistral.log", "a", $LOG_SIZE_MAX, 1)

[formatter_gelfFormatter]
class=djehouty.libgelf.formatters.GELFFormatter
EOF

crudini --set /etc/mistral/mistral.conf DEFAULT log_config_append /etc/mistral/logging-gelf.conf
