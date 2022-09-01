#!/bin/bash
# ===================================================================================
# Init script which sets up certificates in NSSDB for FIPS.
# ===================================================================================

NSSDB=/etc/pki/nssdb
KEYSTORE_SECRET=""

ARGS=()

while [ $# -gt 0 ]; do
  case $1 in
    -d|--database)
      NSSDB="$2"
      shift 2
      ;;
    -p|--password)
      KEYSTORE_SECRET="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${ARGS[@]}"


if [ "$#" -eq 0 ]; then
  echo "Usage: $0 [-d nssdb] path [password]"
  exit 1
fi

KEYSTORE_PATH=$1

if [ ! -d "$NSSDB" ]; then
  echo "Directory $NSSDB does not exist"
  exit 1
fi

if [ ! -e "$NSSDB/pkcs11.txt" ]; then
  echo "Directory $NSSDB does not appear to be a NSS database"
  exit 1
fi

CERTIFICATES=$(ls -1 "$KEYSTORE_PATH"/*.crt 2>/dev/null | wc -l)
if [ "$CERTIFICATES" != 0 ]
then
  for CRT in $KEYSTORE_PATH/*.crt; do
    NAME=$(basename "$CRT" .crt)
    echo "Converting $NAME.crt/$NAME.key to $NAME.p12"
    openssl pkcs12 -export -out "$KEYSTORE_PATH/$NAME.p12" -inkey "$KEYSTORE_PATH/$NAME.key" -in "$CRT" -name "$NAME" -password "pass:$KEYSTORE_SECRET"
  done
else
  if [ "$#" -ne 2 ]; then
    echo "Importing PKCS#12 certificates requires passing the password"
    exit 1
  fi
  KEYSTORE_SECRET=$2
fi 

for P12 in $KEYSTORE_PATH/*.p12; do
  echo "Importing $P12"
  if ! pk12util -i "$P12" -d "$NSSDB" -W "$KEYSTORE_SECRET"; then
    echo "An error occurred. Aborting."
    exit 1
  fi
done

certutil -L -d "$NSSDB"