#!/bin/bash

set -eux

ENV_FILE=/st2-docker/env

if [ -f ${ENV_FILE} ]; then
  source ${ENV_FILE}
fi

# Wait until st2api is ready
# This depends on that st2api is listening on default port
# wget exits with code 6 when it fails to authenticate, which is expected here
wget --tries 5 --retry-connrefused -q -O /dev/null http://localhost:9101 || [ $? -eq 6 ]

# Run custom init scripts which require ST2 to be running
for f in /st2-docker/st2.d/*; do
  case "$f" in
    *.sh) echo "$0: running $f"; . "$f" ;;
    *)    echo "$0: ignoring $f" ;;
  esac
  echo
done
