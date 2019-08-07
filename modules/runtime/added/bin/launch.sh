#!/bin/sh
# ===================================================================================
# Function to add a property/value to existing JAVA_ARGS
add_java_arg() {
  export JAVA_ARGS="${JAVA_ARGS} -D$1=$2"
}

# Funtion which adds a variable which matches the passed string and creates a Java property which is added to the server
# launch args. These properties can then be used directly by the server for property substitution in the server config.
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
    add_java_arg "jgroups.tcp.address" ${BIND}
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

configure_encryption() {
  if [ -n "${KEYSTORE_CRT_PATH}" ]; then
    local keystore_dir="${SERVER_ROOT}/server/conf/keystores"
    local keystore="${keystore_dir}/keystore.p12"
    local keystorePkcs="${keystore_dir}/keystore.pkcs12"
    local password=${KEYSTORE_P12_PASSWORD:-"infinispan"}

    mkdir $keystore_dir
    openssl pkcs12 -export -inkey "${KEYSTORE_CRT_PATH}/tls.key" -in "${KEYSTORE_CRT_PATH}/tls.crt" \
      -out "${keystorePkcs}" -password pass:${password}

    # Only execute keytool if openssl executed successfully
    if [ $? -eq 0 ]; then
      keytool -importkeystore -noprompt -srckeystore ${keystorePkcs} -srcstoretype pkcs12 -srcstorepass ${password} \
        -destkeystore ${keystore} -deststoretype pkcs12 -storepass ${password}
    fi

    export KEYSTORE_P12_PATH=${keystorePkcs}
    export KEYSTORE_P12_PASSWORD=${password}
  fi

  if [ -n "${KEYSTORE_P12_PATH}" ]; then
xml=$(cat <<-XMLEnd
<server-identities>\
  <ssl>\
      <keystore path=\"${KEYSTORE_P12_PATH}\" keystore-password=\"${KEYSTORE_P12_PASSWORD}\"/>\
  </ssl>\
</server-identities>
XMLEnd
)
    sed -i "s|<!-- ##SERVER_IDENTITIES## -->|${xml}|" "${CONFIG_FILE}"
  fi
}

# ===================================================================================
# Entry point for the image which initiates any pre-launch config required before
# executing the server.
# ===================================================================================

set -e
if [ -n "${DEBUG}" ]; then
  set -x
fi

# hostname not available with uib-minimal
BIND=$(cat /etc/hosts | grep -m 1 $(cat /proc/sys/kernel/hostname) | awk '{print $1;}')
SERVER_ROOT=/opt/infinispan
CONFIG_FILE=${SERVER_ROOT}/server/conf/infinispan.xml

# If $ISPN_HOME does not comply with SERVER_ROOT, then create a symlink. Necessary in order to allow overriding of location at build time
if [ ${SERVER_ROOT} != ${ISPN_HOME} ]; then
  ln -s ${SERVER_ROOT} ${ISPN_HOME}
fi

configure_encryption
configure_jgroups

if [ -n "${DEBUG}" ]; then
  cat ${CONFIG_FILE}
fi

exec ${ISPN_HOME}/bin/server.sh --bind-address=${BIND} ${JAVA_ARGS}
