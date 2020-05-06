#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan
BIN=$SERVER_ROOT/bin
CONF=$SERVER_ROOT/server/conf

mkdir -p $BIN $CONF $SERVER_ROOT/data

# Create empty properties files in the event of MANAGED_ENV=true and no identities are provided
touch $CONF/users.properties $CONF/groups.properties

cd $SERVER_ROOT
cp /tmp/artifacts/server $BIN/server-runner
cp -r /tmp/artifacts/config-generator $ADDED_DIR/bin/* $BIN
cp -r $ADDED_DIR/bin/* $BIN
