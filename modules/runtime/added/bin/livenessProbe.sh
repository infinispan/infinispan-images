#!/bin/bash
set -e

source $(dirname $0)/probe-common.sh
curl --http1.1 --insecure ${AUTH} --fail --silent --show-error --output /dev/null --head ${HTTP}://${HOSTNAME}:11222/rest/v2/cache-managers/DefaultCacheManager/health
