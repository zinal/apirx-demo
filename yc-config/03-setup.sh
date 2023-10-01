#! /bin/bash
# Software installation

. ./options.sh

set -e
set -u

ydb_ditto="https://ясубд.рф/binaries/release/23.2.12.3/yasubd-23.2.12.3-linux-amd64.tar.gz"
ydb_base="yasubd-23.2.12.3-linux-amd64"
jmeter_ditto="https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.2.tgz"
jmeter_base="apache-jmeter-5.6.2"
apirx_ditto="https://github.com/zinal/apirx-demo/releases/download/v2023-09-29/apirx_test-1.0-SNAPSHOT.jar"
apirx_file="apirx_test.jar"

ssh ${gw_user}@${gw_host} sudo apt-get install -y -q chrony screen mc curl wget

# Downloading the software
ssh ${gw_user}@${gw_host} mkdir -pv apirx-ditto
ssh ${gw_user}@${gw_host} wget -nv -O apirx-ditto/${ydb_base}.tar.gz ${ydb_ditto}
ssh ${gw_user}@${gw_host} wget -nv -O apirx-ditto/${jmeter_base}.tar.gz ${jmeter_ditto}
ssh ${gw_user}@${gw_host} wget -nv -O apirx-ditto/${apirx_file} ${apirx_ditto}

# Uploading YDB to the nodes
ssh ${gw_user}@${gw_host} scp -B apirx-ditto/${ydb_base}.tar.gz ${vm_user}@${prefix_static}1:.
for i in `seq 1 ${count_dynamic}`; do
    ssh ${gw_user}@${gw_host} scp -B apirx-ditto/${ydb_base}.tar.gz ${vm_user}@${prefix_dynamic}${i}:.
done

# Uploading test tools to the nodes
for i in `seq 1 ${count_run}`; do
    ssh ${gw_user}@${gw_host} scp -B apirx-ditto/${jmeter_base}.tar.gz ${vm_user}@${prefix_run}${i}:.
    ssh ${gw_user}@${gw_host} scp -B apirx-ditto/${apirx_file} ${vm_user}@${prefix_run}${i}:.
done

# Unpacking YDB software
unpackYdb() {
    host_name=$1
    echo "ydb unpack on ${host_name} started."
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} tar xfz ${ydb_base}.tar.gz
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} rm -rf ydbd
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} mv ${ydb_base} ydbd
    echo "ydb unpack on ${host_name} completed."
}
unpackYdb ${prefix_static}1 &
for i in `seq 1 ${count_dynamic}`; do
    unpackYdb ${prefix_dynamic}${i} &
done

# Unpacking JMeter
unpackJMeter() {
    host_name=$1
    echo "jmeter unpack on ${host_name} started."
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} tar xfz ${jmeter_base}.tar.gz
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} rm -rf jmeter
    ssh ${gw_user}@${gw_host} ssh ${vm_user}@${host_name} mv ${jmeter_base} jmeter
    echo "jmeter unpack on ${host_name} completed."
}
for i in `seq 1 ${count_run}`; do
    unpackJMeter ${prefix_run}${i} &
done

wait

# End Of File