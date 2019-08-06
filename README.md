# Infinispan Server Image

This repository contains various artifacts to create Infinispan server images.

## Usage

### UDP Transport
```bash
docker run infinispan/server
```

### TCP Transport
```bash
docker run -e JGROUPS_TRANSPORT=tcp infinispan/server
```

### Kubernetes/Openshift Clustering
When running in a managed environment such as Kubernetes, it is not possible to utilise multicasting for initial node
discovery, thefore we must utilise the JGroups [DNS_PING](http://jgroups.org/manual4/index.html#_dns_ping) protocol to discover cluster members. To enable this, we must
pass the `JGROUPS_DNS_PING_QUERY`, which causes the default discovery protocol of either the udp or tcp stacks to be
overridden by DNS_PING. For example, to utilise the tcp stack with DNS_PING, the following command is required:

```bash
docker run -e JGROUPS_DNS_PING_QUERY="infinispan-dns-ping.myproject.svc.cluster.local" -e JGROUPS_TRANSPORT=tcp infinispan/server
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
