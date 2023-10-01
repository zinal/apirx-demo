#! /bin/sh
# YDB cluster deployment

. ./options.sh

set -e
set -u

# Copy tools to gateway host
ssh ${gw_user}@${gw_host} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
scp -r ydbrun ${gw_user}@${gw_host}:apirx-ditto/ydbrun
scp -r ydbconf ${gw_user}@${gw_host}:apirx-ditto/ydbconf

static_host=${prefix_static}1
ssh ${gw_user}@${gw_host} scp apirx-ditto/ydbrun/FormatDisk.sh ${vm_user}@${static_host}:.
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} sudo adduser ${vm_user} disk

if false; then
# YDB disk formatting
for i in `seq 1 ${data_disk_count}`; do
    disk_id=`yc compute disk get ${static_host}-data${i} --format json | jq -r ".id"`
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash FormatDisk.sh ${disk_id} ydb_disk_${i}
done

# Copy configuration files and startup scripts
echo "Deploying configuration files..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbconf ${vm_user}@${static_host}:.
ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbrun ${vm_user}@${static_host}:.
for i in `seq 1 ${count_dynamic}`; do
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${prefix_dynamic}${i} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
    ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbconf ${vm_user}@${prefix_dynamic}${i}:.
    ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbrun ${vm_user}@${prefix_dynamic}${i}:.
done

# Start YDB static node
echo "Starting YDB static node..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/StartStorage.sh
sleep 30

# Initialize YDB storage
echo "Initializing YDB storage..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/InitStorage.sh "grpc://${static_host}:2135"
fi

# End Of File