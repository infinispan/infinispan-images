#!/bin/bash
set -e
DIR=$(dirname $0)
PACKAGES=$(cat $DIR/packages.txt)
for pkg in $PACKAGES
do
    if rpm --verify $pkg 2> /dev/null 
    then
        rpm -e --nodeps $pkg
    fi
done