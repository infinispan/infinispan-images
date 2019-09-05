#!/bin/bash
set -e

USER=$(sed  -n '/^\s*#/!{p;q}' "${ISPN_HOME}/server/conf/users.properties")
AUTH="--digest -u ${USER/=/:}"
HOSTNAME=$(cat /etc/hosts | grep -m 1 $(cat /proc/sys/kernel/hostname) | awk '{print $1;}')

if grep -q "\<ssl\>" ${ISPN_HOME}/server/conf/infinispan.xml; then
  HTTP="https"
else
  HTTP="http"
fi
