#!/bin/bash
set -e

source $(dirname $0)/probe-common.sh
curl --http1.1 --insecure --fail --silent --show-error -X GET ${PROBE_URL} \
 | grep -q "HEALTHY"
