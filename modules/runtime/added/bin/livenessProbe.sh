#!/bin/bash
set -e

USER=$(sed  -n '/^\s*#/!{p;q}' "${ISPN_HOME}/server/conf/users.properties")
AUTH="--digest -u ${USER/=/:}"
HOSTNAME=$(cat /etc/hosts | grep -m 1 $(cat /proc/sys/kernel/hostname) | awk '{print $1;}')
curl ${AUTH} --fail --silent --show-error --output /dev/null --head http://${HOSTNAME}:11222/rest/v2/cache-managers/DefaultCacheManager/health
