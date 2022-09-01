#!/bin/sh
# ===================================================================================
# Entry point for the image which initiates the JGroups Gossip Router
# ===================================================================================

set -e

# Disabled by default
WF_OPENSSL_ENABLED=${WF_OPENSSL_ENABLED:-false}

JGROUPS_JAR=$(find ${ISPN_HOME}/lib -type f -name "jgroups-*.jar" | head -n 1)
GOSSIP_CLASS="org.jgroups.stack.GossipRouter"

if [ ! -f "${JGROUPS_JAR}" ]; then
    # TODO create native binary of GossipRouter?
    echo "Unable to start Gossip router"
    echo "This image does not have JGroups jar file"
    exit 1
fi

GOSSIP_CLASS="org.jgroups.stack.GossipRouter"
CLASSPATH="${JGROUPS_JAR}"

if [[ "${WF_OPENSSL_ENABLED}" == "true" ]]; then
    for jar in $(find ${ISPN_HOME}/lib -type f -name "wildfly-openssl-*.jar"); do
        CLASSPATH="${CLASSPATH}:${jar}"
    done
fi

exec java ${ROUTER_JAVA_OPTIONS} -cp "${CLASSPATH}" "${GOSSIP_CLASS}" $@
