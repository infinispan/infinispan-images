#!/bin/bash
set -e

HOSTNAME=$(cat /etc/hosts | grep -m 1 $(cat /proc/sys/kernel/hostname) | awk '{print $1;}')

if grep -q "\<ssl\>" ${ISPN_HOME}/server/conf/infinispan.xml; then
  HTTP="https"
else
  HTTP="http"
fi

PROBE_URL=${HTTP}://${HOSTNAME}:11222/rest/v2/cache-managers/DefaultCacheManager/health/status
