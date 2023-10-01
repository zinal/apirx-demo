#! /bin/bash

set -e
set -u

bash 01-create-vms.sh
bash 02-configure-vms.sh
bash 03-setup.sh
bash 04-ydb-deploy.sh

# End Of File