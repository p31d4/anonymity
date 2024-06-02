#!/bin/bash

#------------------------------------------------------------------------------
# user stuff
#------------------------------------------------------------------------------
# check if the script is being running with root privileges
if [ "$EUID" -ne 0 ]
then
    echo "Please run as root"
    exit 1
fi

if [ -e /.dockerenv ]
then
    echo "Docker does not handle partitions very well"
    exit 1
fi

usage() {
    echo "    usage: $1 sdx        - USB device to be formatted - /dev/sdx"
    exit 1
}

if [ -z "$1" ]
then
    usage $0
fi

echo -e "\nBe careful, this script may destroy your device, I'm not responsible for any trouble ;)"
read -p "Proceed? (y/n) " -e PROCEED && [[ ${PROCEED} == [yY] ]] || exit 1
#------------------------------------------------------------------------------

sdx=$1
tmp_dir=$(mktemp --directory)

# UEFI/GPT
# 1MiB (offset) = 512(page size) * 2048 (number of pages)
parted -s "/dev/${sdx}" mklabel gpt mkpart "" fat32 1MiB 1025MiB
parted -s "/dev/${sdx}" set 1 esp on
sleep 0.2
parted -s /dev/${sdx} mkpart "" linux-swap 1025MiB 2049MiB  # Swap partition - 1G
sleep 0.2
parted -s /dev/${sdx} mkpart "" ext4 2049MiB 12289MiB  # root partition - 10G
sleep 0.2
parted -s /dev/${sdx} mkpart "" ext4 12289MiB 100%  # user partition
sleep 0.2

echo "Formating boot partition..."
dd if=/dev/zero of=/dev/${sdx}1 bs=20M status=progress count=50 && sync

# fill devices with zeros
read -p "Fill swap partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}2"
read -p "Fill root partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}3"
read -p "Fill user partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}4"

# Filesystems
mkfs.fat -F32 "/dev/${sdx}1"
mkswap "/dev/${sdx}2"
swapon "/dev/${sdx}2"
mkfs.ext4 "/dev/${sdx}3"
mkfs.ext4 "/dev/${sdx}4"

echo "DONE!"
