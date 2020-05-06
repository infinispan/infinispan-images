#!/bin/bash
set -e

mkdir -p /opt/build
cd /opt/build
tar --strip-components=1 -xvf /tmp/artifacts/config-generator-src.tar.gz
mvn package -DskipTests=true -Pnative
cp config-generator/target/config-generator-*-runner /opt/config-generator

chown -R 185 /opt
chmod -R g+rwX /opt
