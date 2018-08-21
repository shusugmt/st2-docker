#!/bin/bash

set -e

crudini --set /etc/st2/st2.conf metrics driver statsd
crudini --set /etc/st2/st2.conf metrics host statsd-exporter
crudini --set /etc/st2/st2.conf metrics port 9125
