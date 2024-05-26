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
    echo "    usage: $1 sdx        - USB device where the OS ISOs will be stored - /dev/sdx"
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

# fill device with zeros
# time dd if=/dev/zero of=/dev/${sdx} bs=16M status=progress

# msdos partition
parted -s "/dev/${sdx}" mklabel msdos
parted -s "/dev/${sdx}" mkpart primary 1MiB 551MiB
parted -s "/dev/${sdx}" set 1 esp on
parted -s "/dev/${sdx}" set 1 boot on
mkfs.fat -F32 "/dev/${sdx}1"

# ext4 partition
parted -s /dev/${sdx} mkpart primary 551MiB 100%
mkfs.ext4 "/dev/${sdx}2"

# mount partitions
mkdir $tmp_dir/{efi,data}
mount "/dev/${sdx}1" $tmp_dir/efi
mount "/dev/${sdx}2" $tmp_dir/data

# this will work inside the docker image
pushd /tmp/git_repos/grub/EFI32
./grub-install --target=i386-efi -d $PWD/grub-core --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot/" --efi-directory="${tmp_dir}/efi"
popd

grub-install --target=x86_64-efi --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" --efi-directory="${tmp_dir}/efi" # --debug
grub-install --target=i386-pc --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" "/dev/${sdx}"

mkdir ${tmp_dir}/data/boot/iso
chown 1000:1000 ${tmp_dir}/data/boot/iso

# this kelnel version supports Realtek RTL8812BU USB Wireless Adapter
wget https://old.kali.org/kali-images/kali-2019.2/kali-linux-2019.2-amd64.iso \
	-P ${tmp_dir}/data/boot/iso

# based on pendrivelinux.com/downloads/grub.cfg
cp grub.cfg "${tmp_dir}/data/boot/grub/"
