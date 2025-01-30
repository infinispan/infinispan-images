#!/bin/bash
set -e

cd /opt/build

./mvnw package -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml \
    -Pnative \
    -Pdistribution \
    -DskipTests \
    -Dcheckstyle.skip \
    -pl quarkus/server-runner \
    -Dquarkus.native.native-image-xmx=8g \
    -Dmaven.buildNumber.revisionOnScmFailure=no-scm

cp /opt/build/quarkus/server-runner/target/infinispan-quarkus-server-runner-*-runner /opt/server
