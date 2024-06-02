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

sdx=$1
tmp_dir=$(mktemp --directory)

# BIOS/MBR
#parted -s "/dev/${sdx}" mklabel msdos
#parted -s "/dev/${sdx}" mkpart primary 1MiB 551MiB
#parted -s "/dev/${sdx}" set 1 boot on

# UEFI/GPT
# 1MiB (offset) = 512(page size) * 2048 (number of pages)
parted -s "/dev/${sdx}" mklabel gpt mkpart "" fat32 1MiB 551MiB
echo "Formating boot partition..."
dd if=/dev/zero of=/dev/${sdx}1 bs=20M status=progress count=25 && sync
parted -s "/dev/${sdx}" set 1 esp on
mkfs.fat -F32 "/dev/${sdx}1"

# BIOS/MBR
#parted -s /dev/${sdx} mkpart primary 551MiB 100%

# UEFI/GPT
parted -s /dev/${sdx} mkpart "" ext4 551MiB 33319MiB  # iso partition: 32*1024 + 551 (offset) - 32G
# fill device with zeros
read -p "Fill iso partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}2"
mkfs.ext4 "/dev/${sdx}2"  # Force here is too dangerous

parted -s /dev/${sdx} mkpart "" ext4 33319MiB 100%  # user partition
# fill device with zeros
read -p "Fill user partition with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
	shred -v -f -n1 --random-source=/dev/zero "/dev/${sdx}3"
mkfs.ext4 "/dev/${sdx}3"

# mount partitions
mkdir $tmp_dir/{efi,data}
mount "/dev/${sdx}1" $tmp_dir/efi
mount "/dev/${sdx}2" $tmp_dir/data

# For old stuff
#mkdir $tmp_dir/git_repos
#cd $tmp_dir/git_repos
#git clone git://git.savannah.gnu.org/grub.git
#cd $tmp_dir/git_repos/grub
#./bootstrap
#mkdir EFI32
#pushd EFI32/
#../configure --target=i386 --with-platform=efi && make
#echo "Installing grub EFI32 ..."
#./grub-install --target=i386-efi -d $PWD/grub-core --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot/" --efi-directory="${tmp_dir}/efi"
#popd

echo "Installing grub EFI64 ..."
grub-install --target=x86_64-efi --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" --efi-directory="${tmp_dir}/efi" # --debug
echo "Installing grub BIOS ..."
grub-install --target=i386-pc --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" "/dev/${sdx}"

mkdir ${tmp_dir}/data/boot/iso
chown 1000:1000 ${tmp_dir}/data/boot/iso

sync

umount "/dev/${sdx}1"
umount "/dev/${sdx}2"

echo "DONE!"
