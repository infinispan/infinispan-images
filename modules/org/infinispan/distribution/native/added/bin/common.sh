#!/bin/sh

# Use --debug to activate debug mode with an optional argument to specify the port.
# Usage : server.sh --debug
#         server.sh --debug 9797
# By default debug mode is disabled.
DEBUG_MODE="${DEBUG:-false}"
DEBUG_PORT="${DEBUG_PORT:-8787}"

# Use --jmx to activate JMX remoting mode with an optional argument to specify the port.
# Usage : server.sh --jmx
#         server.sh --jmx 1234
# By default JMX remoting is disabled.
JMX_REMOTING="${JMX:-false}"
JMX_PORT="${JMX_PORT:-9999}"

GC_LOG="$GC_LOG"
JAVA_OPTS_EXTRA=""
PROPERTIES=""
while [ "$#" -gt 0 ]
do
    case "$1" in
      --debug)
          DEBUG_MODE=true
          if [ -n "$2" ] && [ "$2" = $(echo "$2" | sed 's/-//') ]; then
              DEBUG_PORT=$2
              shift
          fi
          ;;
      --jmx)
          JMX_REMOTING=true
          if [ -n "$2" ] && [ "$2" = $(echo "$2" | sed 's/-//') ]; then
              JMX_PORT=$2
              shift
          fi
          ;;
      --)
          shift
          break;;
      -s)
          ISPN_ROOT_DIR="$2"
          ARGUMENTS="$ARGUMENTS $1 $2"
          shift
          ;;
      -D*)
          JAVA_OPTS_EXTRA="$JAVA_OPTS_EXTRA '$1'"
          ;;
      -P)
          if [ ! -f "$2" ]; then
            echo "Could not load property file: $2"
            exit
          fi
          while read -r LINE; do
            PROPERTIES="$PROPERTIES '-D$LINE'"
          done < "$2"
          ARGUMENTS="$ARGUMENTS $1 $2"
          shift
          ;;
      *)
          ARGUMENTS="$ARGUMENTS $1"
          ;;
    esac
    shift
done
echo "$PROPERTIES"

GREP="grep"

# Use the maximum available, or set MAX_FD != -1 to use that
MAX_FD="maximum"

# tell linux glibc how many memory pools can be created that are used by malloc
MALLOC_ARENA_MAX="${MALLOC_ARENA_MAX:-1}"
export MALLOC_ARENA_MAX

# Setup ISPN_HOME
RESOLVED_ISPN_HOME=$(cd "$DIRNAME/.." >/dev/null; pwd)
if [ "x$ISPN_HOME" = "x" ]; then
    # get the full path (without any relative bits)
    ISPN_HOME=$RESOLVED_ISPN_HOME
else
  SANITIZED_ISPN_HOME=$(cd "$ISPN_HOME"; pwd)
  if [ "$RESOLVED_ISPN_HOME" != "$SANITIZED_ISPN_HOME" ]; then
    echo ""
    echo "   WARNING:  ISPN_HOME may be pointing to a different installation - unpredictable results may occur."
    echo ""
    echo "             ISPN_HOME: $ISPN_HOME"
    echo ""
    sleep 2s
  fi
fi
export ISPN_HOME

# Read an optional running configuration file
if [ "x$RUN_CONF" = "x" ]; then
    BASEPROGNAME=$(basename "$PROGNAME" .sh)
    RUN_CONF="$DIRNAME/$BASEPROGNAME.conf"
fi
if [ -r "$RUN_CONF" ]; then
    . "$RUN_CONF"
fi

JAVA_OPTS="$JAVA_OPTS_EXTRA $JAVA_OPTS"

# Enable JMX authenticator if needed
if [ "$JMX_REMOTING" = "true" ]; then
    JMX_OPT=$(echo "$JAVA_OPTS" | $GREP "\-Dcom.sun.management.jmxremote")
    if [ "x$JMX_OPT" = "x" ]; then
        JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.port=$JMX_PORT -Djava.security.auth.login.config=$DIRNAME/server-jaas.config -Dcom.sun.management.jmxremote.login.config=ServerJMXConfig -Dcom.sun.management.jmxremote.ssl=false"
    else
        echo "JMX already enabled in JAVA_OPTS, ignoring --jmx argument"
    fi
fi

# consolidate the server and command line opts
CONSOLIDATED_OPTS="$JAVA_OPTS $ARGUMENTS $PROPERTIES"
# process the standalone options
for var in $CONSOLIDATED_OPTS
do
    # Remove quotes
    p=$(echo "$var" | tr -d "'")
    case $p in
        -Dinfinispan.server.root.path=*|--server-root=*)
            ISPN_ROOT_DIR=$(readlink -m "${p#*=}")
            ;;
        -Dinfinispan.server.log.path=*)
            ISPN_LOG_DIR=$(readlink -m "${p#*=}")
            ;;
        -Dinfinispan.server.config.path=*)
            ISPN_CONFIG_DIR=$(readlink -m "${p#*=}")
            ;;
    esac
done

# determine the default base dir, if not set
if [ "x$ISPN_ROOT_DIR" = "x" ]; then
   ISPN_ROOT_DIR="$ISPN_HOME/server"
fi
# determine the default log dir, if not set
if [ "x$ISPN_LOG_DIR" = "x" ]; then
   ISPN_LOG_DIR="$ISPN_ROOT_DIR/log"
fi
# determine the default configuration dir, if not set
if [ "x$ISPN_CONFIG_DIR" = "x" ]; then
   ISPN_CONFIG_DIR="$ISPN_ROOT_DIR/conf"
fi
