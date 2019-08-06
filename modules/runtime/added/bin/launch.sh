#!/bin/sh
# ===================================================================================
# Funtion which adds a variable which matches the passed string and creates a Java property which is added to the server
# launch args. These properties can then be used directly by the server for property substitution in the server config.
add_java_arg() {
  export JAVA_ARGS="$JAVA_ARGS -D$1=$2"
}

env_as_java_arg() {
  local var_name=$1
  local value=${!var_name}
  if [ -n "$value" ]; then
    local property="${var_name,,}"
    property=${property//_/.}
    add_java_arg $property $value
  fi
}

configure_jgroups() {
  local transport="${JGROUPS_TRANSPORT,,}"
  if [ "tcp" = "$transport" ]; then
    add_java_arg "jgroups.tcp.address" $BIND
  fi

  if [ -n "${JGROUPS_DNS_PING_QUERY}" ]; then
    add_java_arg "infinispan.cluster.stack" "dns-ping-${transport}"
    env_as_java_arg "JGROUPS_DNS_PING_ADDRESS"
    env_as_java_arg "JGROUPS_DNS_PING_QUERY"
    env_as_java_arg "JGROUPS_DNS_PING_RECORD_TYPE"
  else
    add_java_arg "infinispan.cluster.stack" "image-${transport}"
  fi
}

# ===================================================================================
# Entry point for the image which initiates any pre-launch config required before
# executing the server.
# ===================================================================================

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

# hostname not available with uib-minimal
BIND=$(cat /etc/hosts | grep -m 1 $(cat /proc/sys/kernel/hostname) | awk '{print $1;}')
SERVER_ROOT=/opt/infinispan

# If $ISPN_HOME does not comply with SERVER_ROOT, then create a symlink. Necessary in order to allow overriding of location at build time
if [ $SERVER_ROOT != $ISPN_HOME ]; then
  ln -s $SERVER_ROOT $ISPN_HOME
fi

configure_jgroups

exec $ISPN_HOME/bin/server.sh --bind-address=$BIND $JAVA_ARGS
