#!/bin/bash
set -e

source $(dirname $0)/probe-common.sh
curl --http1.1 --insecure --fail --silent --show-error --output /dev/null --head ${PROBE_URL}
