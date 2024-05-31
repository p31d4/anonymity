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

# TODO: figure out how to do this with loop
tmp_dir=$(mktemp --directory)

function get_qubes {
    wget https://ftp.qubes-os.org/iso/Qubes-R4.2.3-x86_64.iso -P $1
}

get_qubes ${tmp_dir}

if [ -f ${tmp_dir}/Qubes-R4.2.3-x86_64.iso ]
then
    dd if=${tmp_dir}/Qubes-R4.2.3-x86_64.iso of=/dev/"$1" bs=16M status=progress conv=fdatasync

    # Fix the Error
    #$ sudo fdisk -l /dev/$1
    #GPT PMBR size mismatch (13496787 != 60125183) will be corrected by write.
    #The backup GPT table is not on the end of the device.
    parted -s --fix -l /dev/"$1"
else
    echo "Qubes wasn't downloaded"
fi
