#!/bin/bash
set -e

source $(dirname $0)/probe-common.sh
curl --http1.1 --insecure ${AUTH} --fail --silent --show-error -X GET ${HTTP}://${HOSTNAME}:11222/rest/v2/cache-managers/DefaultCacheManager/health \
 | grep -Po '"health_status":.*?[^\\]",' \
 | grep -q '\"HEALTHY\"'
