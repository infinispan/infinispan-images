# Infinispan Server Images

This repository contains various artifacts to create Infinispan server images.

## Images
Currently we provide the following images which are all based upon the [ubi-minimal](https://catalog.redhat.com/software/containers/detail/5c359a62bed8bd75a2c3fba8)
base image:

- `infinispan/server` - Infinispan is executed using the Java 11 openjdk JVM
- `infinispan/server-native` - Infinispan is executed natively using the [Infinispan Quarkus](https://github.com/infinispan/infinispan-quarkus) binary.

> The `server` and `server-native` images are configured the same. The instructions throughout these docs are applicable
to both images unless otherwise stated.

## Getting Started
To get started with infinispan server on your local machine simply execute:

```bash
docker run -p 11222:11222 infinispan/server
```

or

```bash
podman run --net=host -p 11222:11222 infinispan/server
```

> When utilising [podman](https://podman.io/) it's necessary for the `--net=host` to be passed when not executing as `sudo`.

By default the image has authentication enabled on all exposed endpoints. When executing the above command the image
automatically generates a username/password combo, prints the values to stdout and then starts the Infinispan server with
the authenticated Hotrod and Rest endpoints exposed on port 11222. Therefore, it's necessary to utilise the printed
credentials when attempting to access the exposed endpoints via clients.

It's also possible to provide a username/password combination via environment variables like so:

```bash
docker run -p 11222:11222 -e USER="Titus Bramble" -e PASS="Shambles" infinispan/server
```

> We recommend utilising the auto-generated credentials or USER & PASS env variables for initial development only. Providing
authentication and authorization configuration via a [Identities yaml file](#yaml-configuration) allows for much greater
control.

### HotRod Clients
When connecting a HotRod client to the image, the following SASL properties must be configured on your client (with the username and password properties changed as required):

```java
infinispan.client.hotrod.auth_username=Titus Bramble
infinispan.client.hotrod.auth_password=Shambles
infinispan.client.hotrod.auth_realm=default
infinispan.client.hotrod.auth_server_name=infinispan
infinispan.client.hotrod.sasl_mechanism=DIGEST-MD5
```

## Yaml Configuration
The infinispan image can utilise two optinal yaml configuration files. The identities file provides all identity information,
such as user credentials, role mapping, oauth service etc. Whereas the configuration yaml contains configuration
information required by Infinispan during server startup. This can be used in order to configure JGroups, Endpoints etc.

Below shows how a [docker volume](https://docs.docker.com/storage/volumes/) can be created and mounted in order to run
the Infinispan image with a identities and configuration file located in the current working directory.

```bash
docker run -v $(pwd):/user-config -e IDENTITIES_PATH="/user-config/identities.yaml" -e CONFIG_PATH="/user-config/config.yaml" infinispan/server
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
    auth: true
    enabled: true
    qop: auth
    serverName: infinispan
  memcached:
    enabled: false
  rest:
    auth: true
    enabled: true
jgroups:
  diagnostics: false
  encrypt: false
  transport: tcp
  dnsPing:
    address: ""
    recordType: A
keystore:
  alias: server
  selfSignCert: false
  type: pkcs12
xsite:
  masterCandidate: true

logging:
  console:
    level: trace
    pattern: '%K{level}%d{HH\:mm\:ss,SSS} %-5p [%c] (%t) %s%e%n'
  file:
    level: trace
    path: server/log
    pattern: '%d{yyyy-MM-dd HH\:mm\:ss,SSS} %-5p [%c] (%t) %s%e%n'
  categories:
    com.arjuna: warn
    org.infinispan: info
    org.jgroups: warn
```
However, it is not necessary to provide all of these fields when configuring your image. Instead you can just provide
the relevant parts. For example, to utilise udp for transport and enable the memcached endpoint, your config woudl be
as follows:

```yaml
endpoints:
  memcached:
    enabled: true
jgroups:
  transport: udp
```

### Clustering
The default JGroups stack for the image is currently tcp.

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

#### Encryption
The JGroups encryption protocols ASYM_ENCRYPT and SERIALIZE can be enabled by defining the following in the yaml:

```yaml
jgroups:
  encrypt: true
```

Unfortunately the ASYM_ENCRYPT protocol is vulnerable to man-in-the-middle attacks when configured by itself (see the [JGroups docs for more details](http://jgroups.org/manual4/index.html#SSL_KEY_EXCHANGE)), therefore
we automatically add the SSL_KEY_EXCHANGE protocol to the stack if a [keystore](#keystore) is configured. For example,
the following yaml will ensure that both ASYM_ENCRYPT and SSL_KEY_EXCHANGE protocols are utilised:

```yaml
jgroups:
  encrypt: true
keystore:
  caFile: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
  crtPath: /var/run/secrets/openshift.io/serviceaccount
```

> Note, in order for SSL_KEY_EXCHANGE to be able to create the required SSL sockets, it's necessary for both a `caFile` and `caPath` to be configured.

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
Encryption is automatically enabled for all endpoints if a [keystore](#keystore) is configured, otherwise it is disabled.

### Keystore
In order for the image's endpoint and/or clustering to utilise encryption, it is necessary for a keystore to be defined.
A keystore can be defined in one of two ways.

##### Providing a CRT Path
It's possible to provide a `crtPath` to a directory accessible to the image, that contains a private key and certificate in the
files `tls.key` and `tls.crt` respectively. This results in a pkcs12 keystore being created and loaded by the server to
enable endpoint encryption. Furthermore, it's also possible to provide a path to a certificate authority pem bundle via
the `caFile` key.

```yaml
---
keystore:
  caFile: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt # Only required for JGroups encryption
  crtPath: /var/run/secrets/openshift.io/serviceaccount
  password: customPassword # Optional field, which determines the keystore's password, otherwise a default is used.
```

> This is ideal for managed environments such as Openshift/Kubernetes, as we can simply pass the certificates of the
services CA, i.e. `caFile: /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt`.

##### Providing an existing keystore
Alternatively, existing keystores can be utilised by providing the absolute path of the keystore.

```yaml
  path: /user-config/keystore.jks
  password: customPassword # Required in order to be able to access the keystore
  type: jks # If no type specifed, defaults to pkcs12
```

### Logging
To configure logging you can add the following to your config yaml:

```yaml
logging:
  categories:
    org.infinispan.factories: trace
    org.infinispan.commons.marshall: warn
```

By default, all specified log levels will be output to both the console and log file (/opt/infinispan/server/log/server.log).
If you require different log levels for the console and log file, this is possible by explicitly setting the required
levels like so:

```yaml
logging:
  console:
    level: info
  file:
    level: trace
  categories:
    org.infinispan.factories: trace
```

It's also possible to specify the formatting of a log by providing a `pattern` string for the console and/or
log file element:

```yaml
logging:
  file:
    pattern: '%K{level}%d{HH\:mm\:ss,SSS} %-5p [%c] (%t) %s%e%n'
```

Finally, if you require your log file to be located at a specific location, such as a mounted volume, it's possible to
specify the path of the directory in which it will be stored via:

```yaml
logging:
  file:
    path: some/example/path
```

#### Rest Enabling CORS
It's possible to configure the CORS rules for the REST endpoint as follows:

```yaml
endpoints:
  rest:
    cors:
      - name: restrict-host1
        allowedOrigins:
          - http://host1
          - https://host1
        allowedMethods:
          - GET

      - name: allow-all
        allowCredentials: true
        allowedOrigins:
          - '*'
        allowedMethods:
          - GET
          - OPTIONS
          - POST
          - PUT
          - DELETE
        allowedHeaders:
          - X-Custom-Header
          - Upgrade-Insecure-Requests
        exposeHeaders:
          - Key-Content-Type
        maxAgeSeconds: 1
```

The `name`, `allowedOrigins` and `allowedMethods` keys are mandatory.

The rules are evaluated sequentially based on the "Origin" header set by the browser; in the example above if the origin
is either "http://host1" or "https://host1" the rule "restrict host1" will apply, otherwise the next rule will be tested.
Since the rule "allow ALL" permits all origins, any script coming from a different origin will be able to perform the
methods specified and use the headers supplied. Detailed information about the different configuration parameters can
be found in the [Infinispan REST guide](https://infinispan.org/docs/stable/titles/rest/rest.html#rest_server_cors).

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

## Custom Infinispan XML Configuration
If you require more control of the server's configuration than it is also possible to configure the Infinispan server directly using XML. To do this, it is necessary to set the entrypoint of the docker image to `/opt/infinispan/bin/server.sh` and for the custom Infinispan/JGroups xml files to be copied to a mounted docker volume like so:

```bash
docker volume create example-vol
cp custom-infinispan.xml custom-jgroups.xml /var/lib/docker/volumes/example-vol/_data
docker run -it -v example-vol:/user-config --entrypoint "/opt/infinispan/bin/server.sh"  infinispan/server -b SITE_LOCAL -c /user-config/custom-infinispan.xml
```

## Debugging

### Image Configuration
The image scripts that are used to configure and launch the Infinispan server can be debugged by setting the environment variable `DEBUG=TRUE` as follows:

```bash
 docker run -e DEBUG=true infinispan/server
```

### Infinispan Server
It's also possible to debug the Infinispan server in the image by setting the `DEBUG_PORT` environment variable as follows:
```bash
docker run -e DEBUG_PORT="*:8787" -p 8787:8787 infinispan/server
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

### Provided Tools
In order to keep the image's size as small as possible, we utilise the [ubi-minimal](https://developers.redhat.com/products/rhel/ubi/) image.
Consequently, the image does not provide all of the tools that are commonly available in linux distributions.
Below is a list of common tools/recipes that are useful for debugging.

| Task | Command |
| ---- | ------- |
| Text editor | vi |
| Get the PID of the java process | ps -fC java |
| Get socket/file information | lsof |
| List all open files excluding network sockets | lsof |grep -v "IPv[46]" |
| List all TCP sockets | ss -t -a |
| List all UDP sockets | ss -u -a |
| Network configuration | ip |
| Show unicast routes | ip route |
| Show multicast routes | ip maddress |

## Kubernetes

### Liveness and Readiness Probes
It's recommended to utilise Infinispan's REST endpoint in order to determine if the server is ready/live. To do this, you
can utilise the Kubernetes [httpGet probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) as follows:

```yaml
livenessProbe:
httpGet:
  path: /rest/v2/cache-managers/default/health/status
  port: 11222
failureThreshold: 5
initialDelaySeconds: 10
successThreshold: 1
timeoutSeconds: 10
readinessProbe:
httpGet:
  path: /rest/v2/cache-managers/default/health/status
  port: 11222
failureThreshold: 5
initialDelaySeconds: 10
successThreshold: 1
timeoutSeconds: 10
```

## Creating Images
### Prerequisites
All of our images are created using the [Cekit](https://cekit.io) tool. Installation instructions can be found [here](https://docs.cekit.io/en/latest/handbook/installation/instructions.html).

> The exact [dependencies](https://docs.cekit.io/en/latest/handbook/installation/dependencies.html#) that you will require depends on the "builder" that you want to use in order to create your image. For example OSBS has different requirements to Docker.


#### Cekit Patch
Due to https://github.com/cekit/cekit/issues/642, it is necessary to install the following one-off patch for 'cekit' via pip
in order for multi-stage builds to work as expected:

```bash
pip3 install -U https://github.com/goldmann/cekit/archive/gh-642-multi-stage-handling-artifacts.zip
```

### Image

### Descriptor Files
We leverage [cekit descriptor files](https://docs.cekit.io/en/latest/descriptor/image.html) in order to create the different
image types.

- `server-openjdk.yaml` - Creates the `infinispan/server` image with a natively compiled config-generator
- `server-native.yaml` - Creates the `infinispan/server-native` image with a natively compiled config-generator and server


### Recreate Image Releases
We recommend pulling stable image releases from [Quay.io](https://quay.io/infinispan/server) or [Docker Hub](https://hub.docker.com/r/jboss/infinispan-server),
however it is also possible to recreate stable releases of an image.

To recreate a given release, it's necessary to checkout the corresponding git tag and build using `cekit --descriptor <descriptor-file> build <build-engine>`.
For example, the following commands will recreate the `infinispan/server:10.0.0.Dev05` image.

```bash
git checkout 11.0.0.Dev05
cekit --descriptor server-openjdk.yaml build docker
```

## License
See [License](LICENSE.md).
