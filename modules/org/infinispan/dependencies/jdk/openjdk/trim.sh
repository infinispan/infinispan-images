#!/bin/bash
#set -e
DIR=$(dirname $0)
PACKAGES=$(cat $DIR/packages.txt)
for pkg in $PACKAGES
do
    cmd=`rpm --verify $pkg 2> /dev/null`
    rc=$?
    if [[ $rc -eq 0 ]]
    then
        echo "${pkg} exists"
        rpm -e --nodeps $pkg
    else
        echo "${pkg} does not exist"
    fi
done
