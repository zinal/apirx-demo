#! /bin/sh

set -e
set -u

DB_ENDPOINT=$1

. $HOME/ydbrun/Config.sh

ydbd -s ${DB_ENDPOINT} admin blobstorage config init --yaml-file ${HOME}/ydbconf/storage.yaml

# End Of File