#!/bin/bash
set -e

cd /opt/build
./mvnw package -s /tmp/scripts/quarkus.infinispan.src/maven-settings.xml -Dnative -DskipTests -pl '!cli,!integration-tests,!integration-tests/embedded,!integration-tests/server'
cp /opt/build/server-runner/target/infinispan-quarkus-server-runner-*-runner /opt/server
