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
xsite:
  name: ""
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

### XSite Replication
In order to configure the image for xsite replication, it's necessary to provide the external address and port of the
local site as well as the external address and port of all remote sites as part of the `config.yaml` at startup.
Below shows the expected format:

```yaml
---
xsite:
  address: # Externally accessible IP Address of local site
  name: LON
  port: 7200
  backups:
    - address: # Externally accessible  IP address of NYC site
      name: NYC
      port: 7200
```

## Image Architecture
The image consists of two [Cekit](https://cekit.io) modules, `modules/dependencies` and `modules/runtimes`. The
dependencies module is a simply yaml file that should be used for installing all dependencies required by the image.
Whereas the runtimes module contains all scripts required by the server during image execution. Files at the root of
the `runtimes` modules are used to extract the default server distribution and files/dir in the `added`
dir are copied to the extracted server's root in order to add/overwrite existing files in the distribution.

The entrypoint for the image is `modules/runtimes/added/bin/launch.sh`, which is a minimal bash script that calls the
[ConfigGenerator](https://github.com/infinispan/infinispan-image-artifacts/tree/master) program to generate the server
configuration based upon the user supplied yaml files, before then launching the server.

## Creating Images
### Prerequisites
All of our images are created using the [Cekit](https://cekit.io) tool. Installation instructions can be found [here](https://docs.cekit.io/en/latest/handbook/installation/instructions.html).

> The exact [dependencies](https://docs.cekit.io/en/latest/handbook/installation/dependencies.html#) that you will require depends on the "builder" that you want to use in order to create your image. For example OSBS has different requirements to Docker.

### Infinispan
The default image configuration creates an image using the latest release of the Infinispan server and the
infinispan image artifacts. To create this image as `infinispan/server` using the Docker builder,
issue the following commands:
```bash
cekit build docker
```

#### Recreate Image Releases
We recommend pulling stable image releases from [Quay.io](https://quay.io/infinispan/server) or [Docker Hub](https://hub.docker.com/r/jboss/infinispan-server),
however it is also possible to recreate stable releases of an image.

To recreate a given release, it's necessary to checkout the corresponding git tag and build using `cekit build <build-engine>`.

#### Local Snapshot Builds
In order to create the image using a local SNAPSHOT version of the Infinispan server, execute the following command,
updating the path attribute to be equal to the local path of your SNAPSHOT distribution zip.

```bash
cekit build --overrides '{"artifacts": [{"name": "server.zip", "path": "infinispan-server-10.0.0-SNAPSHOT.zip"}]}' docker
```

Similarly in order to build an image using a SNAPSHOT of the config generator, issue the following commands:
```bash
cekit build --overrides '{"artifacts": [{"name": "config-generator.jar", "path": "config-generator-1.0.0-SNAPSHOT.jar"}]}' docker
```

### Data Grid
In order to create an image using the Red Hat Data Grid server, it's necessary to have an active Red Hat kerberos session. The image can then be created using the following command:
```bash
cekit build --overrides-file dg-override.yaml docker
```

## License
See [License](LICENSE.md).
