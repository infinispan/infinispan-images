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

function nextImageVersion() {
    BUILD=1
    if [[ "${CURRENT_VERSION}" == ${ISPN_VERSION}* ]]; then
        BUILD=${CURRENT_VERSION##*-}
        BUILD=$((BUILD+1))
    fi
    echo ${ISPN_VERSION}-${BUILD}
}

requiredEnv ISPN_VERSION DESCRIPTOR

YAML="${DESCRIPTOR}.yaml"
if [[ "${DESCRIPTOR}" == "server-openjdk" ]]; then
    # Single stage build
    CURRENT_VERSION=$(yq '.version' ${YAML})
    IMAGE_VERSION=$(nextImageVersion)
    yq -i ".version = \"${IMAGE_VERSION}\"" ${YAML}
    yq -i ".artifacts[0].url = \"https://github.com/infinispan/infinispan/releases/download/${ISPN_VERSION}/infinispan-server-${ISPN_VERSION}.zip\"" ${YAML}
    yq -i "(.labels[] | select(.name == \"version\" or .name == \"release\") | .value) = \"${ISPN_VERSION}\"" ${YAML}
else
    # Multi-stage build
    CURRENT_VERSION=$(yq '.[0].version' ${YAML})
    IMAGE_VERSION=$(nextImageVersion)

    # Update builder descriptor
    yq -i ".[0].version = \"${IMAGE_VERSION}\"" ${YAML}
    yq -i ".[0].artifacts[0].url = \"https://github.com/infinispan/infinispan/archive/${ISPN_VERSION}.tar.gz\"" ${YAML}

    # Update runner descriptor
    yq -i ".[1].version = \"${IMAGE_VERSION}\"" ${YAML}
    yq -i "(.[1].labels[] | select(.name == \"version\" or .name == \"release\") | .value) = \"${ISPN_VERSION}\"" ${YAML}
fi
echo "${IMAGE_VERSION}"
