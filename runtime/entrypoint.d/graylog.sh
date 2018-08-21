
ST2_LOG_COMPONENTS="\
actionrunner
api
api.gunicorn
auth
auth.gunicorn
garbagecollector
notifier
resultstracker
rulesengine
sensorcontainer
stream
stream.gunicorn
timersengine
workflowengine
"

for ST2_LOG_COMPONENT in $ST2_LOG_COMPONENTS; do

cat << EOF > /etc/st2/logging.${ST2_LOG_COMPONENT}.conf
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
args=("/var/log/st2/${ST2_LOG_COMPONENT}.log", "a", 1024*1024, 1)

[formatter_gelfFormatter]
class=st2common.logging.formatters.GelfLogFormatter
format=%(message)s
EOF

done

# st2actionrunner need special care: need one file per pid
crudini --set /etc/st2/logging.actionrunner.conf handler_gelfHandler args '("/var/log/st2/actionrunner.%s.log" % str(os.getpid()), "a", 1024*1024, 1)'
