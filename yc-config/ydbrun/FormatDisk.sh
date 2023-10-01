#! /bin/sh

set -e
set -u

disk_id=$1
disk_label=$2
disk_name=/dev/disk/by-id/virtio-${disk_id}

echo "Partitioning ${disk_name} -> ${disk_label}..."

sudo parted ${disk_name} mklabel gpt -s
sudo parted -a optimal ${disk_name} mkpart primary '0%' '100%'
sudo parted ${disk_name} name 1 ${disk_label}
sudo partprobe ${disk_name}

sleep 3

part_path=/dev/disk/by-partlabel/${disk_label}
echo "Obliterating ${part_path}..."
LD_LIBRARY_PATH=$(pwd)/ydbd/lib ./ydbd/bin/ydbd admin bs disk obliterate ${part_path}
echo "...Success!"
