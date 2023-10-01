#! /bin/sh

set -u
set -e

DB_ENDPOINT="$1"

YDB_HOME=$HOME/ydbd
LD_LIBRARY_PATH=$YDB_HOME/lib
PATH=$YDB_HOME/bin:$PATH

export LD_LIBRARY_PATH
export PATH

ydb version --disable-checks

set +e
ydb -d /Root/testdb -e ${DB_ENDPOINT} scheme describe hashes >/dev/null 2>&1
if [ "$?" == "0" ]; then
    set -e
    ydb -d /Root/testdb -e ${DB_ENDPOINT} yql -s 'DROP TABLE hashes;' </dev/null
fi
set -e

ydb -d /Root/testdb -e ${DB_ENDPOINT} yql -s '
CREATE TABLE hashes(hash UInt64 NOT NULL, src Text, PRIMARY KEY(hash))
 WITH(AUTO_PARTITIONING_BY_LOAD=ENABLED,
      AUTO_PARTITIONING_MIN_PARTITIONS_COUNT=200,
      AUTO_PARTITIONING_MAX_PARTITIONS_COUNT=300,
      AUTO_PARTITIONING_PARTITION_SIZE_MB=500);' </dev/null
