#!/bin/sh
# ===================================================================================
# Entry point for the image which initiates any pre-launch config required before
# executing the server.
# ===================================================================================
SERVER_ROOT=/opt/infinispan

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

# If $ISPN_HOME does not comply with SERVER_ROOT, then create a symlink. Necessary in order to allow overriding of location at build time
if [ $SERVER_ROOT != $ISPN_HOME ]; then
  ln -s $SERVER_ROOT $ISPN_HOME
fi

exec $ISPN_HOME/bin/server.sh
