#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan

mkdir -p $SERVER_ROOT
cd $SERVER_ROOT
bsdtar --strip-components=1 -xvf /tmp/artifacts/server

cp -r $ADDED_DIR/bin/* $SERVER_ROOT/bin
rm $SERVER_ROOT/server/conf/infinispan-local.xml

# Remove Rocksdb platform dependent files if they exist
zip -d $SERVER_ROOT/lib/rocksdbjni-*.jar "*musl.so" "*dll" "*aarch*so" "*jnilib" "*ppc64*so" "*linux32*so" || true

# Remove unused windows files
rm $SERVER_ROOT/bin/*.bat

# Remove schema ~ 650K
rm -rf $SERVER_ROOT/docs/schema
