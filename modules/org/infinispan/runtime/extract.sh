#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan

cp $ADDED_DIR/bin/* $SERVER_ROOT/bin
chown -R 185 /opt
chmod -R g+rwX $SERVER_ROOT
