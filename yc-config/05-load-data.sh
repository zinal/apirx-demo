#! /bin/bash
# YDB cluster deployment

. ./options.sh

set -e
set -u

work_host=${prefix_run}1
yql_host=${prefix_dynamic}1

echo "Copying files to the gateway..."
scp ../run-*.jmx ${gw_user}@${gw_host}:apirx-ditto/
scp ../ReplaceTable.sh ${gw_user}@${gw_host}:apirx-ditto/
scp apirx_test.xml ${gw_user}@${gw_host}:apirx-ditto/apirx_test.template

echo "Copying files to the hosts..."
ssh ${gw_user}@${gw_host} scp apirx-ditto/ReplaceTable.sh ${vm_user}@${yql_host}:.
for i in `seq 1 ${count_run}`; do
    ssh ${gw_user}@${gw_host} scp apirx-ditto/'run-*.jmx' ${vm_user}@${prefix_run}${i}:.
done

echo "Adjusting the tool configuration..."
ssh ${gw_user}@${gw_host} "sed 's|DB_NODE|${yql_host}|' < apirx-ditto/apirx_test.template >apirx-ditto/apirx_test.xml"
for i in `seq 1 ${count_run}`; do
    ssh ${gw_user}@${gw_host} scp apirx-ditto/apirx_test.xml ${vm_user}@${prefix_run}${i}:.
done

echo "Creating the table..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${yql_host} bash ReplaceTable.sh "grpc://${yql_host}:2136"

echo "Starting the tool..."
for i in `seq 1 ${count_run}`; do
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${prefix_run}${i} screen -d -m java -jar apirx_test.jar
done

sleep 10

echo "Starting the data generator..."
ssh ${gw_user}@${gw_host} ssh ${vm_user}@${work_host} screen -d -m ./jmeter/bin/jmeter -n -j run-generate.log -t run-generate.jmx

# End Of File