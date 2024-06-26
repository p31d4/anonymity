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
read -p "Fill device with zeros (this can take some time)? (y/n) " -e ZERO && [[ ${ZERO} == [yY] ]] && \
time dd if=/dev/zero of=/dev/${sdx} bs=16M status=progress

# BIOS/MBR
#parted -s "/dev/${sdx}" mklabel msdos
#parted -s "/dev/${sdx}" mkpart primary 1MiB 551MiB
#parted -s "/dev/${sdx}" set 1 boot on

# UEFI/GPT
parted -s "/dev/${sdx}" mklabel gpt mkpart "" fat32 1MiB 551MiB
parted -s "/dev/${sdx}" set 1 esp on
mkfs.fat -F32 "/dev/${sdx}1"

# BIOS/MBR
#parted -s /dev/${sdx} mkpart primary 551MiB 100%

# UEFI/GPT
parted -s /dev/${sdx} mkpart "" ext4 551MiB 100%
mkfs.ext4 "/dev/${sdx}2"

# mount partitions
mkdir $tmp_dir/{efi,data}
mount "/dev/${sdx}1" $tmp_dir/efi
mount "/dev/${sdx}2" $tmp_dir/data

# this will work inside the docker image
echo "Installing grub EFI32 ..."
pushd /tmp/git_repos/grub/EFI32
./grub-install --target=i386-efi -d $PWD/grub-core --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot/" --efi-directory="${tmp_dir}/efi"
popd

echo "Installing grub EFI64 ..."
grub-install --target=x86_64-efi --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" --efi-directory="${tmp_dir}/efi" # --debug
echo "Installing grub BIOS ..."
grub-install --target=i386-pc --force --removable --no-floppy --boot-directory="${tmp_dir}/data/boot" "/dev/${sdx}"

mkdir ${tmp_dir}/data/boot/iso
chown 1000:1000 ${tmp_dir}/data/boot/iso

function get_kali_old {
    # this kelnel version supports Realtek RTL8812BU USB Wireless Adapter
    wget https://old.kali.org/kali-images/kali-2019.2/kali-linux-2019.2-amd64.iso \
        -P $1
}

get_tails() {
    pushd $1
    wget https://tails.net/tails-signing.key
    gpg --import < tails-signing.key
    gpg --keyring=/usr/share/keyrings/debian-keyring.gpg --export chris@chris-lamb.co.uk | gpg --import
    gpg --keyid-format 0xlong --check-sigs A490D0F4D311A4153E2BB7CADBB802B258ACD84F
    # this asks for confirmation in an interactive way
    gpg --lsign-key A490D0F4D311A4153E2BB7CADBB802B258ACD84F

    wget https://mirrors.edge.kernel.org/tails/stable/tails-amd64-6.3/tails-amd64-6.3.iso
    wget https://mirrors.edge.kernel.org/tails/stable/tails-amd64-6.3/tails-amd64-6.3.iso.sig
    TZ=UTC gpg --no-options --keyid-format long --verify tails-amd64-6.3.iso.sig tails-amd64-6.3.iso
    popd
}

get_kali_old ${tmp_dir}/data/boot/iso
get_tails ${tmp_dir}/data/boot/iso

# based on pendrivelinux.com/downloads/grub.cfg
cp grub.cfg "${tmp_dir}/data/boot/grub/"

rm -r "${tmp_dir}"/data/lost+found/
umount "/dev/${sdx}1"
umount "/dev/${sdx}2"
