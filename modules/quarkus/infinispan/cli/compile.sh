#!/bin/bash
set -e

cd /opt/build
./mvnw package -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml -Dnative -DskipTests -pl 'cli'
cp /opt/build/cli/target/infinispan-cli /opt/cli
