#! /bin/bash
# YDB cluster deployment

. ./options.sh

set -e
set -u

static_host=${prefix_static}1

# Copy tools to gateway host
ssh ${gw_user}@${gw_host} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
scp -r ydbrun ${gw_user}@${gw_host}:apirx-ditto/ydbrun
scp -r ydbconf ${gw_user}@${gw_host}:apirx-ditto/ydbconf

# Copy configuration files and startup scripts
echo "Deploying configuration files..."
echo "...${static_host}"
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbconf ${vm_user}@${static_host}:.
ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbrun ${vm_user}@${static_host}:.
for i in `seq 1 ${count_dynamic}`; do
    h=${prefix_dynamic}${i}
    echo "...${h}"
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${h} rm -rf apirx-ditto/ydbrun apirx-ditto/ydbconf
    ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbconf ${vm_user}@${h}:.
    ssh ${gw_user}@${gw_host} scp -r apirx-ditto/ydbrun ${vm_user}@${h}:.
done

echo "Formatting YDB data disks..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} sudo adduser ${vm_user} disk
for i in `seq 1 ${data_disk_count}`; do
    disk_id=`yc compute disk get ${static_host}-data${i} --format json | jq -r ".id"`
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/FormatDisk.sh ${disk_id} ydb_disk_${i}
done

echo "Starting YDB static node..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/StartStorage.sh
sleep 30

echo "Initializing YDB storage..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/InitStorage.sh "grpc://${static_host}:2135"

echo "Creating YDB database..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${static_host} bash ./ydbrun/CreateDatabase.sh "grpc://${static_host}:2135" /Root/testdb ssd 17

echo "Starting the database nodes..."
for i in `seq 1 ${count_dynamic}`; do
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${prefix_dynamic}${i} bash ./ydbrun/StartDynamic.sh "grpc://${static_host}:2135"
done

# End Of File