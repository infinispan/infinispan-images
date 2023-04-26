#!/bin/bash
set -e

cd /opt/build
./mvnw clean install -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml -Pnative -Pdistribution -DskipTests -am -pl 'quarkus/cli'
cp /opt/build/quarkus/cli/target/infinispan-cli /opt/cli
