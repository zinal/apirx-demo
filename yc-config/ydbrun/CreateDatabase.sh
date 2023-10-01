#! /bin/sh
# YDB database creation

set -e
set -u

DB_ENDPOINT=$1
DB_NAME=$2
DB_POOL=$3
DB_GROUPS=$4

. $HOME/ydbrun/Config.sh

TMPLOG=`mktemp /tmp/ydbd.createdb.XXXXXX`
trap "rm -f ${TMPLOG}" EXIT

ydbd -s ${DB_ENDPOINT} admin database ${DB_NAME} create ${DB_POOL}:${DB_GROUPS} >>${TMPLOG} 2>&1

# Ensure success, e.g. no error messages even when the exit code is zero.
set +e
if grep -qE '^ERROR: ' ${TMPLOG}; then
  cat ${TMPLOG};
  exit 1
fi
exit 0

# End Of File