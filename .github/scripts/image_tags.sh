#!/usr/bin/env bash
set -e

if [[ "$RUNNER_DEBUG" == "1" ]]; then
  set -x
fi

function requiredEnv() {
  for ENV in $@; do
      if [ -z "${!ENV}" ]; then
        echo "${ENV} variable must be set"
        exit 1
      fi
  done
}

requiredEnv IMAGE_VERSION DESCRIPTOR TYPE

if [[ "${DESCRIPTOR}" == "server-openjdk" ]]; then
  IMAGE="server"
else
  IMAGE=${DESCRIPTOR}
fi

ISPN_VERSION=${IMAGE_VERSION%-*}
MAJOR_MINOR_VERSION=${ISPN_VERSION%.*.*}

TAGS="${MAJOR_MINOR_VERSION} ${ISPN_VERSION} ${IMAGE_VERSION}"
if [[ "${TYPE}" == "latest" ]]; then
  TAGS+=" latest"
fi

FQ_TAGS=""
for REPO in "quay.io/" ""; do
  for TAG in ${TAGS}; do
    FQ_TAGS+="${REPO}infinispan/${IMAGE}:${TAG},"
  done
done
echo ${FQ_TAGS::-1}
