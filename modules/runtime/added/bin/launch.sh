#!/bin/sh
# ===================================================================================
# Entry point for the image which initiates any pre-launch config required before
# executing the server.
# ===================================================================================

generate_user_or_password() {
  echo $(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
}

printLn() {
  format='# %-76s #\n'
  printf "$format" "$1"
}

printBorder() {
  printf '#%.0s' {1..80}
  printf "\n"
}

set -e
if [ -n "${DEBUG}" ]; then
  set -x
fi

SERVER_ROOT=/opt/infinispan

# If $ISPN_HOME does not comply with SERVER_ROOT, then create a symlink. Necessary in order to allow overriding of location at build time
if [ ${SERVER_ROOT} != ${ISPN_HOME} ]; then
  ln -s ${SERVER_ROOT} ${ISPN_HOME}
fi

# If no identities file provided, then use provided user/pass or generate as required
if [ -z ${IDENTITIES_PATH} ]; then
  printBorder
  printLn "IDENTITIES_PATH not specified"
  if [ -n "${USER}" ] && [ -n "${PASS}" ]; then
    printLn "Generating Identities yaml using USER and PASS env vars"
  else
    USER=$(generate_user_or_password)
    PASS=$(generate_user_or_password)
    printLn "USER and/or PASS env variables not specified"
    printLn "Auto generating user and password"
    printLn "Generated User: ${USER}"
    printLn "Generated Password: ${PASS}"
  fi
  printBorder

identities=$(cat <<-YamlEnd
credentials:
  - username: ${USER}
    password: ${PASS}
YamlEnd
)
  export IDENTITIES_PATH=${ISPN_HOME}/server/conf/generated-identities.yaml
  echo "${identities}" > ${IDENTITIES_PATH}
fi

java -jar ${ISPN_HOME}/bin/config-generator.jar ${ISPN_HOME}/server/conf ${IDENTITIES_PATH} ${CONFIG_PATH}

if [ -n "${DEBUG}" ]; then
  cat ${SERVER_ROOT}/server/conf/*.xml
fi

exec ${ISPN_HOME}/bin/server.sh
