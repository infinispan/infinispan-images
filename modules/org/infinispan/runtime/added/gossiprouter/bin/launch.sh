#!/bin/sh
# ===================================================================================
# Entry point for the image which initiates the JGroups Gossip Router
# ===================================================================================

set -e

JGROUPS_JAR=`find ${ISPN_HOME} -type f -name "jgroups-*.jar" | head -n 1`
GOSSIP_CLASS="org.jgroups.stack.GossipRouter"

if [ ! -f "${JGROUPS_JAR}" ]; then
    # TODO create native binary of GossipRouter?
    echo "Unable to start Gossip router"
    echo "This image does not have JGroups jar file"
    exit 1
fi

exec java ${ROUTER_JAVA_OPTIONS} -cp ${JGROUPS_JAR} ${GOSSIP_CLASS} $@