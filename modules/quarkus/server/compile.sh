#!/bin/bash
set -e

mkdir -p /opt/build
cd /opt/build
tar --strip-components=1 -xvf /tmp/artifacts/server-src.tar.gz
mvn clean install -Dnative -DskipTests=true
cp server-runner/target/infinispan-quarkus-server-runner-*-runner /opt/server
