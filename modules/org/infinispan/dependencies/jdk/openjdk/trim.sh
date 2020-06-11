#!/bin/bash
set -e
DIR=$(dirname $0)
PACKAGES=$(cat $DIR/packages.txt)
rpm -e --nodeps $PACKAGES
