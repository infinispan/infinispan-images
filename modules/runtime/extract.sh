#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
ARTIFACTS_DIR=/tmp/artifacts
DISTRIBUTION=$(ls $ARTIFACTS_DIR | grep infinispan*)
SERVER_ROOT=/opt/infinispan

mkdir -p $SERVER_ROOT
cd $SERVER_ROOT
bsdtar --strip-components=1 -xvf $ARTIFACTS_DIR/$DISTRIBUTION

cp $ADDED_DIR/launch.sh $SERVER_ROOT/bin
cp $ADDED_DIR/java-opts.sh $SERVER_ROOT/bin
cp $ADDED_DIR/server.conf $SERVER_ROOT/bin

chown -R 185 /opt
chmod -R g+rwX $SERVER_ROOT
