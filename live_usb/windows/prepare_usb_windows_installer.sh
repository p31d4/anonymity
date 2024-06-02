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
    echo "DOCKER IS CURRENTLY NOT SUPPORTED BECAUSE"
    echo "  lsblk --noheadings --output FSTYPE /dev/sd..."
    echo "RETURNS NOTHING"
    exit 1
fi

usage() {
    echo "    usage: $1 sdx windows_iso"
    echo "              sdx            - USB device to be formatted - /dev/sdx"
    echo "              windows_iso    - path to the Windows ISO file"
    exit 1
}

if [ "$#" -ne 2 ]
then
    usage $0
fi

echo -e "\nBe careful, this script may destroy your device, I'm not responsible for any trouble ;)"
read -p "Proceed? (y/n) " -e PROCEED && [[ ${PROCEED} == [yY] ]] || exit 1
#------------------------------------------------------------------------------

sdx=$1
tmp_dir=$(mktemp --directory)

#TODO: add error handlers
# BIOS/MBR - WINDOWS
# The windows partition has to be the first one, otherwise you will get the error:
# "A media driver your computer needs is missing"
# and I have no idea why
parted -s "/dev/${sdx}" mklabel msdos
parted -s "/dev/${sdx}" mkpart primary fat32 4MiB 8196MiB  # 8GiB
parted -s "/dev/${sdx}" set 1 boot on
sleep 0.2
read -p "Fill windows partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}1"
mkfs.fat -F32 "/dev/${sdx}1"

# EFI
parted -s "/dev/${sdx}" mkpart primary fat32 8196MiB 8696MiB  #500MiB
sleep 0.2
read -p "Fill efi partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}2"
mkfs.fat -F32 "/dev/${sdx}2"

# GRUB/DATA
# partition for grub and Linux distributions
parted -s /dev/${sdx} mkpart primary 8696MiB 100%
sleep 0.2
read -p "Fill grub/data partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}3"
mkfs.ext4 "/dev/${sdx}3"  # Force here is too dangerous

# mount partitions
mkdir $tmp_dir/{efi,grub}
mount "/dev/${sdx}2" $tmp_dir/efi
mount "/dev/${sdx}3" $tmp_dir/grub

# With this, you can boot in partition 2 and execute the following
# comands at the grub terminal to load the windows installer (JUST FOR FUN):
# set root=(hd0,msdos1)  # this can change
# chainloader /efi/boot/bootx64.efi
# #ntldr /bootmgr
# boot
echo "Installing grub EFI64 ..."
grub-install --target=x86_64-efi --force --removable --no-floppy --boot-directory="${tmp_dir}/grub/boot" --efi-directory="${tmp_dir}/efi" # --debug

mkdir ${tmp_dir}/grub/boot/iso
chown 1000:1000 ${tmp_dir}/grub/boot/iso  # a place for Linux ISOs

sync

umount "/dev/${sdx}2"
umount "/dev/${sdx}3"

#TODO: check if the ISO image is not mounted
# WOEUSB STUFF
# Here I could have done something like the cmds bellow
# BUT, I would have the burden of fragment the file install.wim because it has more than 4294967295 bytes
# and the Woeusb guys already did a good job there
#
#parted --script /dev/${sdx} mkpart primary fat32 4MiB -- -1s
#mkdosfs -F 32 -n 'Windows USB' "/dev/${sdx}1"
##mkfs -t ntfs "/dev/${sdx}1"  # ntfs will fill device with zeros
#mount --options loop,ro --types udf,iso9660 windows.iso /tmp/tmp_iso_content
#grub-install --target=i386-pc --force --boot-directory="${tmp_dir}/windows" "/dev/${sdx}"
#Copy iso content to mounted sdx1 partition
#
# On Kali (Docker is currently no working)
# sudo apt install dosfstools findutils grep gawk grub2-common grub-pc-bin grub-efi ntfs-3g p7zip-full parted util-linux wget wimtools
/usr/bin/woeusb --partition "$2" /dev/${sdx}1

echo "DONE!"

# In the end I will go with the VirtualBox option, as long as I just wanna play with
# https://github.com/mandiant/commando-vm
