# Infinispan Images

This repository contains various artifacts to create Infinispan server and CLI images.

Currently we provide the following images which are all based upon the [ubi-minimal](https://catalog.redhat.com/software/containers/detail/5c359a62bed8bd75a2c3fba8)
base image:

- `infinispan/server` - Infinispan is executed using the Java 21 openjdk JVM
- `infinispan/cli` - A natively compiled version of the Infinispan CLI.

## CLI
```bash
docker run -it infinispan/cli
```

The image's endpoint is the CLI binary, so it's possible to pass the usual CLI args straight to the image. For example:

```bash
docker run -it infinispan/cli --connect http://<server-url>:11222
```

You can find complete documentation for the CLI, in our [CLI User Guide](https://infinispan.org/docs/stable/titles/cli/cli.html).

## Server

### Getting Started
To get started with infinispan server on your local machine simply execute:

```bash
docker run -p 11222:11222 infinispan/server
```

or

```bash
podman run --net=host -p 11222:11222 infinispan/server
```

> When utilising [podman](https://podman.io/) it's necessary for the `--net=host` to be passed when not executing as `sudo`.

By default the image has authentication and enabled on all exposed endpoints. When executing the above command the image
automatically generates a username/password combo with the "admin" role, prints the values to stdout and then starts the Infinispan server with
the authenticated Hotrod and Rest endpoints exposed on port 11222. Therefore, it's necessary to utilise the printed
credentials when attempting to access the exposed endpoints via clients.

It's also possible to provide a admin username/password combination via environment variables like so:

```bash
docker run -p 11222:11222 -e USER="admin" -e PASS="changeme" infinispan/server
```

> We recommend utilising the auto-generated credentials or USER & PASS env variables for initial development only. Providing
authentication and authorization configuration via a [Identities Batch file](#identities-batch) allows for much greater
control.

#### HotRod Clients
When connecting a HotRod client to the image, the following SASL properties must be configured on your client (with the username and password properties changed as required):

```properties
infinispan.client.hotrod.auth_username=admin
infinispan.client.hotrod.auth_password=changme
infinispan.client.hotrod.sasl_mechanism=DIGEST-MD5
```

### Identities Batch
User identities and roles can be defined by providing a cli batch file via the `IDENTITIES_BATCH` env variable.
All of the cli commands defined in this file are executed before the server is started, therefore it's only possible to
execute offline commands otherwise the container will fail. For example, including `create cache ...` in the batch would
fail as it requires a connection to an Infinispan server.

Infinispan provides implicit roles for some users.

[TIP] Check Infinispan [documentation](https://infinispan.org/docs/stable/titles/configuring/configuring.html#default-user-roles_security-authorization)
to know more about implicit roles and authorization

Below is an example Identities batch CLI file `identities.batch`, that defines four users and their role:

```bash
user create "Alan Shearer" -p "striker9" -g admin
user create "observer" -p "secret1" 
user create "deployer" -p "secret2" 
user create "Rigoberta Baldini" -p "secret3" -g monitor
```

To run the image using a local `identities.batch`, execute:

```bash
docker run -v $(pwd):/user-config -e IDENTITIES_BATCH="/user-config/identities.batch" -p 11222:11222 infinispan/server
```

### Server Configuration
The Infinispan image passes all container arguments to the created server, therefore it's possible to configure the server in
the same manner as a non-containerised deployment.

Below shows how a [docker volume](https://docs.docker.com/storage/volumes/) can be created and mounted in order to run
the Infinispan image with the local configuration file `my-infinispan-config.xml` located in the users current working directory.

```bash
docker run -v $(pwd):/user-config -e IDENTITIES_BATCH="/user-config/identities.batch" -p 11222:11222 infinispan/server -c /user-config/my-infinispan-config.xml
```

#### Kubernetes/Openshift Clustering
When running in a managed environment such as Kubernetes, it is not possible to utilise multicasting for initial node
discovery, thefore we must utilise the JGroups [DNS_PING](http://jgroups.org/manual4/index.html#_dns_ping) protocol to
discover cluster members. To enable this, we must provide the `jgroups.dnsPing.query` property and configure the
`kubernetes` stack.

To utilise the tcp stack with DNS_PING, execute the following config:

```bash
docker run -v $(pwd):/user-config infinispan/server --bind-address=0.0.0.0  -Dinfinispan.cluster.stack=kubernetes -Djgroups.dns.query="infinispan-dns-ping.myproject.svc.cluster.local"
```

#### Java Properties
It's possible to provide additional java properties and JVM options to the server images via the `JAVA_OPTIONS` env variable.
For example, to quickly configure CORS without providing a server.yaml file, it's possible to do the following:

```bash
docker run -e JAVA_OPTIONS="-Dinfinispan.cors.enableAll=https://host.domain:port" infinispan/server
```

#### Deploying artifacts to the server lib directory
Deploy artifacts to the server lib directory using the `SERVER_LIBS` env variable.
For example, to add the PostgreSQL JDBC driver to the server:

```bash
docker run -e SERVER_LIBS="org.postgresql:postgresql:42.3.1" infinispan/server
```

The `SERVER_LIBS` variable supports multiple, space-separated artifacts represented as URLs or as Maven coordinates. Archive artifacts in `.tar`, `.tar.gz` or `.zip` formats will be extracted. Refer to the [CLI](https://infinispan.org/docs/stable/titles/cli/cli.html#install1) `install` command help to learn about all possible arguments and options. 

## Debugging

### Image Configuration
The image scripts that are used to configure and launch the executables can be debugged by setting the environment variable `DEBUG=TRUE` as follows:

```bash
 docker run -e DEBUG=true infinispan/<image-name>
```

### Infinispan Server
It's also possible to debug the Infinispan server in the image by setting the `DEBUG_PORT` environment variable as follows:
```bash
docker run -e DEBUG_PORT="*:8787" -p 8787:8787 infinispan/server
```
### Image Tools
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
