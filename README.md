# Infinispan Server Image

This repository contains various artifacts to create Infinispan server images.

## Usage

### Clustering

#### UDP Transport
```bash
docker run infinispan/server
```

#### TCP Transport
```bash
docker run -e JGROUPS_TRANSPORT=tcp infinispan/server
```

#### Kubernetes/Openshift Clustering
When running in a managed environment such as Kubernetes, it is not possible to utilise multicasting for initial node
discovery, thefore we must utilise the JGroups [DNS_PING](http://jgroups.org/manual4/index.html#_dns_ping) protocol to discover cluster members. To enable this, we must
pass the `JGROUPS_DNS_PING_QUERY`, which causes the default discovery protocol of either the udp or tcp stacks to be
overridden by DNS_PING. For example, to utilise the tcp stack with DNS_PING, the following command is required:

```bash
docker run -e JGROUPS_DNS_PING_QUERY="infinispan-dns-ping.myproject.svc.cluster.local" -e JGROUPS_TRANSPORT=tcp infinispan/server
```

### Endpoints
The Infinispan image exposes both the REST and HotRod endpoints via a single port `11222`.

#### Encryption
By default encryption is disabled on our endpoints, however it can be enabled by one of two environment variables.

##### KEYSTORE_CRT_PATH
Set `KEYSTORE_CRT_PATH` to a directory containing certificate/key pairs in the format tls.key and tls.crt respectively.
This results in a pkcs12 keystore being created and loaded by the server to enable endpoint encryption. Note, if the
`KEYSTORE_P12_PASSWORD` env var is set, it's value will be used as the password for the generated keystore.

> This is ideal for managed environments such as Openshift/Kubernetes, as we can simply pass the certificates of the
services CA, i.e. `KEYSTORE_CRT_PATH=/var/run/secrets/kubernetes.io/serviceaccount`

##### KEYSTORE_P12_PATH
Alternatively, existing pkcs12 keystores can be utilised by providing the absolute path of the keystore via
`KEYSTORE_P12_PATH` and `KEYSTORE_P12_PASSWORD`.

With standalone docker, keystores can be added by mounting a [docker volume](https://docs.docker.com/storage/volumes/)
when running the container. For example:

```bash
docker volume create ks-vol
cp example_ks.p12 $DOCKER_HOME/volumes/test-vol/_data
docker run -v ks-vol:/keystore -e KEYSTORE_P12_PATH="/keystore/example_ks.p12" -e KEYSTORE_P12_PASSWORD="Password" infinispan/server
```


## Creating Images
### Prerequisites
All of our images are created using the [Cekit](https://cekit.io) tool. Installation instructions can be found [here](https://docs.cekit.io/en/latest/handbook/installation/instructions.html).

> The exact [dependencies](https://docs.cekit.io/en/latest/handbook/installation/dependencies.html#) that you will require depends on the "builder" that you want to use in order to create your image. For example OSBS has different requirements to Docker.

### Infinispan
This is the default that will create an image using the upstream Infinispan server. To create this image as `infinispan/server` using the Docker builder, issue the following command:
```bash
cekit build docker
```

### Data Grid
In order to create an image using the Red Hat Data Grid server, it's necessary to have an active Red Hat kerberos session. The image can then be created using the following command:
```bash
cekit build --overrides-file dg-override.yaml docker
```

## License
See [License](LICENSE.md).
