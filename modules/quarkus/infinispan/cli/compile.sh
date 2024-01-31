#!/bin/bash
set -e

cd /opt/build

./mvnw package -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml \
    -Pnative \
    -Pdistribution \
    -DskipTests \
    -pl 'quarkus/cli' \
    -Dquarkus.native.native-image-xmx=8g \
    -Dmaven.buildNumber.revisionOnScmFailure=no-scm

cp /opt/build/quarkus/cli/target/infinispan-cli /opt/cli
