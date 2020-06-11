#!/bin/bash
set -e

ADDED_DIR=$(dirname $0)/added
SERVER_ROOT=/opt/infinispan

mkdir -p $SERVER_ROOT
cd $SERVER_ROOT
bsdtar --strip-components=1 -xvf /tmp/artifacts/server

if jar -tf /tmp/artifacts/config-generator 2>&1 /dev/null; then
    # If the provided config-generator artifact is a valid jar, then add the extension so that we know to execute on
    # the JVM in bin/launch.sh
    cp /tmp/artifacts/config-generator $SERVER_ROOT/bin/config-generator.jar
else
    cp /tmp/artifacts/config-generator $SERVER_ROOT/bin
fi

cp -r $ADDED_DIR/bin/* $SERVER_ROOT/bin
rm $SERVER_ROOT/server/conf/infinispan-local.xml

# Remove Rocksdb platform dependent files
zip -d $SERVER_ROOT/lib/rocksdbjni-*.jar "*musl.so" "*dll" "*aarch*so" "*jnilib" "*ppc64*so" "*linux32*so"

# Remove unused windows files
rm $SERVER_ROOT/bin/*.bat

# Remove schema ~ 650K
rm -rf $SERVER_ROOT/docs/schema
