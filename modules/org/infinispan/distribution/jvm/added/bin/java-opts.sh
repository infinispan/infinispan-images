#!/bin/sh
# ===================================================================================
## Generic startup script for running arbitrary Java applications with
## being optimized for running in containers
##
## get_java_opts imported version from https://github.com/jboss-container-images/openjdk/blob/ubi9/modules/run/artifacts/opt/jboss/container/java/run/run-java.sh
## ===================================================================================
if [ -n "${DEBUG:-}" ]; then
 set -x
fi

# ksh is different for defining local vars
if [ -n "${KSH_VERSION:-}" ]; then
  alias local=typeset
fi

export JBOSS_CONTAINER_UTIL_LOGGING_MODULE="${JBOSS_CONTAINER_UTIL_LOGGING_MODULE-/opt/jboss/container/util/logging}"
export JBOSS_CONTAINER_JAVA_RUN_MODULE="${JBOSS_CONTAINER_JAVA_RUN_MODULE-/opt/jboss/container/java/run}"

# Default the application dir to the S2I deployment dir
if [ -z "$JAVA_APP_DIR" ]
  then JAVA_APP_DIR=/deployments
fi

source "$JBOSS_CONTAINER_UTIL_LOGGING_MODULE/logging.sh"

# ==========================================================
# Generic run script for running arbitrary Java applications
#
# This has forked (and diverged) from:
# at https://github.com/fabric8io/run-java-sh
#
# ==========================================================

# Combine all java options
get_java_options() {
  local jvm_opts
  local debug_opts
  local proxy_opts
  local opts
  if [ -f "${JBOSS_CONTAINER_JAVA_JVM_MODULE}/java-default-options" ]; then
    jvm_opts=$(${JBOSS_CONTAINER_JAVA_JVM_MODULE}/java-default-options)
  fi
  if [ -f "${JBOSS_CONTAINER_JAVA_JVM_MODULE}/debug-options" ]; then
    debug_opts=$(${JBOSS_CONTAINER_JAVA_JVM_MODULE}/debug-options)
  fi
  if [ -f "${JBOSS_CONTAINER_JAVA_PROXY_MODULE}/proxy-options" ]; then
    source "${JBOSS_CONTAINER_JAVA_PROXY_MODULE}/proxy-options"
    proxy_opts="$(proxy_options)"
  fi

  opts=${JAVA_OPTS-${debug_opts} ${proxy_opts} ${jvm_opts} ${JAVA_OPTS_APPEND}}
  # Normalize spaces with awk (i.e. trim and eliminate double spaces)
  echo "${opts}" | awk '$1=$1'
}

java_opts() {
   get_java_options
}
