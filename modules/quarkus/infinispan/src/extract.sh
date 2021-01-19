#!/bin/bash
set -e

mkdir -p /opt/build
cd /opt/build
tar --strip-components=1 -xvf /tmp/artifacts/quarkus-src.tar.gz
