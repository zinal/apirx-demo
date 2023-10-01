#! /bin/sh
# YDB cluster deployment

. ./options.sh

set -e
set -u

# Copy tools to gateway host
ssh ${gw_user}@${gw_host} rm -rf apirx-ditto/ydbrun
scp -r ydbrun ${gw_user}@${gw_host}:apirx-ditto/ydbrun

host_name=${prefix_static}1
ssh ${gw_user}@${gw_host} scp apirx-ditto/ydbrun/FormatDisk.sh ${vm_user}@${host_name}:.
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} sudo adduser ${vm_user} disk

# YDB disk formatting
for i in `seq 1 ${data_disk_count}`; do
    disk_id=`yc compute disk get ${host_name}-data${i} --format json | jq -r ".id"`
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} bash FormatDisk.sh ${disk_id} ydb_disk_${i}
done

# End Of File