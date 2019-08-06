#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
# Must be the same as artifact name+path defined in module.yaml
ARTIFACT=/tmp/artifacts/server.zip
SERVER_ROOT=/opt/infinispan

mkdir -p $SERVER_ROOT
cd $SERVER_ROOT
bsdtar --strip-components=1 -xvf $ARTIFACT

cp -r $ADDED_DIR/bin/* $SERVER_ROOT/bin
cp -r $ADDED_DIR/conf/* $SERVER_ROOT/server/conf

chown -R 185 /opt
chmod -R g+rwX $SERVER_ROOT
