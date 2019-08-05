#!/bin/sh
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

exec $ISPN_HOME/bin/server.sh \
--bind-address=$BIND \
-Dinfinispan.cluster.stack=$JGROUPS_STACK
