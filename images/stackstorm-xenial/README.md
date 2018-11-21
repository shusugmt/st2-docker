
## Building images

```
docker build -t stackstorm/stackstorm:xenial .

docker build -t stackstorm/stackstorm:xenial-2.9.1 --build-arg ST2_VERSION=2.9.1 .
docker build -t stackstorm/stackstorm:xenial-2.9.0 --build-arg ST2_VERSION=2.9.0 .
docker build -t stackstorm/stackstorm:xenial-2.8.1 --build-arg ST2_VERSION=2.8.1 .

docker build -t stackstorm/stackstorm:xenial-dev --build-arg ST2_REPO=unstable --build-arg NODE_REPO=node_8.x .
```

## st2-self-test

```
apt-get -y install uuid-runtime
export ST2_AUTH_TOKEN=$(st2 auth $ST2_USER -p $ST2_PASSWORD -t)
/opt/stackstorm/st2/bin/st2-self-check
```

## Insecure keys

- st2 datastore key
- SSL self-signed cert for nginx/st2web
- ssh key for stanley user
