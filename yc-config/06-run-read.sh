#! /bin/bash
# YDB cluster deployment

. ./options.sh

set -e
set -u

echo "Starting the workload..."
for i in `seq 1 ${count_run}`; do
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${prefix_run}${i} screen -d -m ./jmeter/bin/jmeter -n -j run-read.log -t run-read.jmx
done

# End Of File