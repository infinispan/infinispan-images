#!/bin/bash
set -e

cd /opt/build
mvn clean install -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml -Dnative -DskipTests -pl 'cli'
cp /opt/build/cli/target/ispn-cli /opt/cli
