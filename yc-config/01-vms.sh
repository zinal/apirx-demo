#! /bin/sh
# Создание виртуальных машин Yandex Cloud для работы кластера YDB.

. ./options.sh

set -u
set +e

# Runners
nodes_base=run
nodes_begin=1
nodes_end=3

. ./supp/vms.sh
. ./supp/host.sh

# Dynamic nodes
nodes_base=ydb-d
nodes_begin=1
nodes_end=9

. ./supp/vms.sh
. ./supp/host.sh

# Static node
nodes_base=ydb-d
nodes_begin=1
nodes_end=1
disk_count=9

. ./supp/vms.sh
. ./supp/host.sh

# End Of File
