#! /bin/bash

set -e
set -u

bash 01-create-vms.sh
bash 02-configure-vms.sh
bash 03-setup.sh
bash 04-ydb-deploy.sh
sleep 30
bash 05-load-data.sh

# End Of File