#! /bin/bash
# YDB cluster deployment

. ./options.sh

set -e
set -u

work_host=${prefix_run}1
yql_host=${prefix_dynamic}1

echo "Creating the table..."
scp ../ReplaceTable.sh ${gw_user}@${gw_host}:apirx-ditto/
ssh ${gw_user}@${gw_host} scp apirx-ditto/ReplaceTable.sh ${vm_user}@${yql_host}:.
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${yql_host} bash ReplaceTable.sh "grpc://${yql_host}:2136"

echo "Starting the tool..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${work_host} screen -d -m java -jar apirx_test.jar

# End Of File