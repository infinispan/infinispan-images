# Infinispan Images
## Creating Images
### Prerequisites
All of our images are created using the [Cekit](https://cekit.io) tool. Installation instructions can be found [here](https://docs.cekit.io/en/latest/handbook/installation/instructions.html).

> The exact [dependencies](https://docs.cekit.io/en/latest/handbook/installation/dependencies.html#) that you will require depends on the "builder" that you want to use in order to create your image. For example OSBS has different requirements to Docker.

### Image

### Descriptor Files
We leverage [cekit descriptor files](https://docs.cekit.io/en/latest/descriptor/image.html) in order to create the different
image types.

- `server-openjdk.yaml` - Creates the `infinispan/server` image.
- `server-native.yaml` - Creates the `infinispan/server-native` image.
- `cli.yaml` - Creates the `infinispan/cli` image with a natively compiled cli.
- `server-dev-native.yaml` - Creates the `infinispan/server-native` image using local artifact paths that must be added to the descriptor.
- `cli-dev.yaml` - Creates the `infinispan/cli` image using a local cli executable that must be added to the descriptor.

### Recreate Image Releases
We recommend pulling stable image releases from [Quay.io](https://quay.io/infinispan/server) or [Docker Hub](https://hub.docker.com/r/jboss/infinispan-server),
however it is also possible to recreate stable releases of an image.

To recreate a given release, it's necessary to checkout the corresponding git tag and build using `cekit --descriptor <descriptor-file> build <build-engine>`.
For example, the following commands will recreate the `infinispan/server:10.0.0.Dev05` image.

```bash
git checkout 11.0.0.Dev05
cekit --descriptor server-openjdk.yaml build docker
```

### Development Images
The `*-dev-*.yaml` descriptors can be used to create local images for development purposes. In order to use these it's
necessary to update the paths of the artifacts in the descriptor then issue the following command:

```
BUILD_ENGINE="podman"
DESCRIPTOR="server-dev-native.yaml"
cekit -v --descriptor $DESCRIPTOR build $BUILD_ENGINE
```
