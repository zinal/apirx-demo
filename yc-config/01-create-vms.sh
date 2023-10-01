#! /bin/sh

. ./options.sh

set -u
set -e
echo "Retrieving public SSH keyfile ${gw_keyfile} from host ${gw_host}..."
ssh ${gw_user}@${gw_host} cat ${gw_keyfile} >keyfile.tmp
ssh ${gw_user}@${gw_host} rm -f .ssh/known_hosts
set +e

checkLimit() {
  grep "The limit on maximum number of active operations has exceeded" mkinst.tmp | wc -l | (read x && echo $x)
}

makeDisks() {
    host_base=$1
    nodes_begin=1
    nodes_end=$2
    disk_count=$3
    disk_type=$4
    disk_size=$5
    rm -f mkinst.tmp
    for i in `seq ${nodes_begin} ${nodes_end}`; do
        vm_name="${host_base}${i}"
        for j in `seq 1 ${disk_count}`; do
            vm_disk_data="${host_base}${i}-data${j}"
            echo "...${vm_disk_data}"
            while true; do
                yc compute disk create ${vm_disk_data} --zone ${yc_zone} \
                    --type ${disk_type} --size ${disk_size} --async >mkinst.tmp 2>&1
                cnt=`checkLimit`
                if [ "$cnt" == "0" ]; then break; else sleep 5; fi
            done
        done
    done
    cnt=`grep "ERROR:" mkinst.tmp | wc -l`
    if [ $cnt -gt 0 ]; then
        echo "*** ERROR: disk creation failed, ABORTING!"
        cat mkinst.tmp
        exit 1
    fi
}

waitDisks() {
    while true; do
        wcnt=`yc compute disk list --format json-rest | jq '.[].status' | grep -v READY | wc -l | (read x y && echo $x)`
        if [ "$wcnt" == "0" ]; then
            echo "...success!"
            break
        fi
        echo "...pending: ${wcnt}..."
        sleep 5
    done
}

makeVMs() {
    host_base=$1
    nodes_begin=1
    nodes_end=$2
    disk_count=$3
    vm_cores=$4
    vm_mem=$5
    set +u
    platform=$6
    if [ -z ${platform} ]; then
        platform=${yc_platform}
    fi
    set -u
    for i in `seq ${nodes_begin} ${nodes_end}`; do
        vm_name="${host_base}${i}"
        vm_disk_boot="${host_base}${i}-boot"
        disk_datum=""
        if [ ${disk_count} -gt 0 ]; then
            for j in `seq 1 ${disk_count}`; do
                disk_datum="$disk_datum --attach-disk disk-name=${host_base}${i}-data${j},auto-delete=true"
            done
        fi
        echo "...${vm_name}"
        while true; do
            yc compute instance create ${vm_name} --zone ${yc_zone} \
            --platform ${platform} \
            --ssh-key keyfile.tmp \
            --create-boot-disk ${yc_vm_image},name=${vm_disk_boot},type=${boot_disk_class},size=${boot_disk_size},auto-delete=true \
            ${disk_datum} --network-settings type=software-accelerated \
            --network-interface subnet-name=${yc_subnet},dns-record-spec="{name=${vm_name}.ru-central1.internal.}" \
            --memory ${vm_mem} --cores ${vm_cores} --async >mkinst.tmp 2>&1
            cnt=`checkLimit`
            if [ "$cnt" == "0" ]; then break; else sleep 10; fi
        done
    done
    cnt=`grep "ERROR:" mkinst.tmp | wc -l`
    if [ $cnt -gt 0 ]; then
        echo "*** ERROR: VM creation failed, ABORTING!"
        cat mkinst.tmp
        exit 1
    fi
}

echo "Creating data disks..."
makeDisks ${prefix_static} 1 ${data_disk_count} ${data_disk_class} ${data_disk_size}

echo "Creating runner VMs..."
makeVMs ${prefix_run} ${count_run} 0 ${cpu_run} ${mem_run}

echo "Creating YDB dynamic VMs..."
makeVMs ${prefix_dynamic} ${count_dynamic} 0 ${cpu_dynamic} ${mem_dynamic}

echo "Waiting for disks to get ready..."
waitDisks

echo "Creating YDB static VM..."
makeVMs ${prefix_static} 1 ${data_disk_count} ${cpu_static} ${mem_static} standard-v2
