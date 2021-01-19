#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
CLI_ROOT=/opt/infinispan

mkdir -p $CLI_ROOT
cp /tmp/artifacts/cli $CLI_ROOT
chown -R 185 /opt
chmod -R g+rwX $CLI_ROOT
