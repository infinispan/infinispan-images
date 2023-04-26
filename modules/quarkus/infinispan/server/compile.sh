#!/bin/bash
set -e

cd /opt/build
./mvnw clean install -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml -Pnative -Pdistribution -DskipTests -am -pl quarkus/server/deployment,quarkus/server-runner
cp /opt/build/quarkus/server-runner/target/infinispan-quarkus-server-runner-*-runner /opt/server
