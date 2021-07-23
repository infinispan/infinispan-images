#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan
GOSSIP_ROOT=/opt/gossiprouter

mkdir -p ${GOSSIP_ROOT}/bin

cp $ADDED_DIR/bin/* $SERVER_ROOT/bin
cp ${ADDED_DIR}/gossiprouter/bin/* ${GOSSIP_ROOT}/bin
chown -R 185 /opt
chmod -R g+rwX $SERVER_ROOT
chmod -R g+rwX ${GOSSIP_ROOT}
