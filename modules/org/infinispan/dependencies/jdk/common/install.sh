#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added

# Override default java.config file so that tls is not disabled
cp $ADDED_DIR/java.config /etc/crypto-policies/back-ends/java.config
