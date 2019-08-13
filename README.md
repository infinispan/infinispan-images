# Infinispan Server Image

This repository contains various artifacts to create Infinispan server images.

## Usage
The infinispan image utilies two yaml configuration files. The identities file provides all identity information, such as
user credentials, role mapping, oauth service etc, and is mandatory. Whereas the configuration yaml is optional, but
supplies configuration information required by Infinispan during server startup. This can be used in order to configure
JGroups, Endpoints etc.

Below shows how a [docker volume](https://docs.docker.com/storage/volumes/) can be created and mounted in order to run
the Infinispan image with a provided the identity and configuration file.

```bash
docker volume create example-vol
cp config.yaml identities.yaml /var/lib/docker/volumes/example-vol/_data
docker run -v example-vol:/user-config -e IDENTITIES_PATH="/user-config/identities.yaml" -e CONFIG_PATH="/user-config/config.yaml" infinispan/server
```
### Identities Yaml
Below is an example Identities yaml, that provides a list of user credentials. All of the users specified in this
file are loaded by the server and there credentials can then be used to access the configured endpoints, e.g. HotRod.

```yaml
credentials:
  - username: Alan Shearer
    password: striker9
    roles:
      - admin
  - username: Nolberto Solano
    password: winger7
    roles:
      - dev
```

### Config Yaml
Below is an example configuration file which shows the current default values used by the image if not provided by the
user configuration yaml.
```yaml
infinispan:
  clusterName: infinispan
endpoints:
  hotrod:
    enabled: true
    qup: auth
    serverName: infinispan
  memcached:
    enabled: false
  rest:
    enabled: true
jgroups:
  transport: udp
  dnsPing:
    address: ""
    recordType: A
keystore:
  alias: server
```
However, it is not necessary to provide all of these fields when configuring your image. Instead you can just provide
the relevant parts. For example, to utilise tcp for transport and enable the memcached endpoint, your config woudl be
as follows:

```yaml
endpoints:
  memcached:
    enabled: true
jgroups:
  transport: tcp
```

### Clustering
The default JGroups stack for the image is currently udp.

#### Kubernetes/Openshift Clustering
When running in a managed environment such as Kubernetes, it is not possible to utilise multicasting for initial node
discovery, thefore we must utilise the JGroups [DNS_PING](http://jgroups.org/manual4/index.html#_dns_ping) protocol to
discover cluster members. To enable this, we must provide the `jgroups.dnsPing.query` element in the configuration yaml.
This causes the default discovery protocol of either the udp or tcp stacks to be overridden by the DNS_PING protocol.

For example, to utilise the tcp stack with DNS_PING, the following config is required:

```yaml
jgroups:
  transport: tcp
  dnsPing:
    query: infinispan-dns-ping.myproject.svc.cluster.local
```

### Endpoints
The Infinispan image exposes both the REST and HotRod endpoints via a single port `11222`.

The memcached port is also available via port `11221`, however it currently does not support authentication and therefore
it must be enabled in the config yaml as show below:
```yaml
---
endpoints:
  memcached:
    enabled: true
```
Similarly, it's also possible to disable the HotRod and/or REST endpoints by setting `enabled: false` on the respective
endpoint's configuration element.

#### Encryption
By default encryption is disabled on our endpoints, however it can be enabled by one of two ways.

##### Providing a CRT Path
It's possible to provide a path to a directory accessible to the image, that contains certificate/key pairs in the
format tls.key and tls.crt respectively. This results in a pkcs12 keystore being created and loaded by the server to
enable endpoint encryption.

```yaml
---
keystore:
  crtPath: /var/run/secrets/openshift.io/serviceaccount
  password: customPassword # Optional field, which determines the keystore's password, otherwise a default is used.
```

> This is ideal for managed environments such as Openshift/Kubernetes, as we can simply pass the certificates of the
services CA, i.e. `/var/run/secrets/kubernetes.io/serviceaccount`.

##### Providing an existing keystore
Alternatively, existing pkcs12 keystores can be utilised by providing the absolute path of the keystore.

```yaml
  path: /user-config/keystore.p12
  password: customPassword # Required in order to be able to access the keystore
```

## Creating Images
### Prerequisites
All of our images are created using the [Cekit](https://cekit.io) tool. Installation instructions can be found [here](https://docs.cekit.io/en/latest/handbook/installation/instructions.html).

> The exact [dependencies](https://docs.cekit.io/en/latest/handbook/installation/dependencies.html#) that you will require depends on the "builder" that you want to use in order to create your image. For example OSBS has different requirements to Docker.

### Infinispan
This is the default that will create an image using the latest release of the upstream Infinispan server and the
config-generator. To create this image as `infinispan/server` using the Docker builder, issue the following commands:
```bash
cekit build docker
```

#### Snapshot Builds
In order to create the image using the latest SNAPSHOT release of the Infinispan server and config-generator, execute
the following commands, updating the path value of the last command to utilise the location of your distribution zip.

```bash
cd config-generator
mvn clean install
cd ..
cekit build --overrides '{"artifacts": [{"name": "server.zip", "path": "infinispan-server-10.0.0-SNAPSHOT.zip"}]}' docker
```

### Data Grid
In order to create an image using the Red Hat Data Grid server, it's necessary to have an active Red Hat kerberos session. The image can then be created using the following command:
```bash
cekit build --overrides-file dg-override.yaml docker
```

## License
See [License](LICENSE.md).
