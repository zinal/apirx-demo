#! /bin/bash
# VM basic configuration

. ./options.sh

ssh ${gw_user}@${gw_host} resolvectl flush-caches

setupNodes() {
    host_base=$1
    nodes_begin=1
    nodes_end=$2
    echo "Validating network access..."
    while true; do
        num_fail=0
        for i in `seq ${nodes_begin} ${nodes_end}`; do
            vm_name="${host_base}${i}"
            ZODAK_TEST=`ssh ${gw_user}@${gw_host} ssh -o StrictHostKeyChecking=no ${vm_user}@${vm_name} echo ZODAK 2>/dev/null`
            if [ "$ZODAK_TEST" == "ZODAK" ]; then
                echo "Host ${vm_name} is available."
            else
                echo "Host ${vm_name} IS NOT AVAILABLE!"
                num_fail=`echo "$num_fail + 1" | bc`
            fi
        done
        if [ $num_fail -gt 0 ]; then
            echo "*** Cannot move forward, $num_fail hosts unavailable!"
        else
            echo "*** VMs are ready, moving forward..."
            break
        fi
    done
    echo "Configuring hosts..."
    for i in `seq ${nodes_begin} ${nodes_end}`; do
        vm_name="${host_base}${i}"
        echo "...${vm_name}"
        ssh ${gw_user}@${gw_host} ssh ${vm_user}@${vm_name} sudo hostnamectl set-hostname ${vm_name}
        ssh ${gw_user}@${gw_host} ssh ${vm_user}@${vm_name} sudo timedatectl set-timezone Europe/Moscow
        ssh ${gw_user}@${gw_host} ssh ${vm_user}@${vm_name} sudo apt-get install -y -q screen
        ssh ${gw_user}@${gw_host} ssh ${vm_user}@${vm_name} screen -d -m sudo apt-get install -y -q chrony mc curl wget parted openjdk-17-jdk
    done
}

setupNodes ${prefix_run} ${count_run}
setupNodes ${prefix_dynamic} ${count_dynamic}
setupNodes ${prefix_static} 1

# End Of File