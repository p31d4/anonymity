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
    echo "    usage: $1 sdxn        - device where the OS ISOs will be stored - probably /dev/sdx2"
    exit 1
}

if [ -z "$1" ]
then
    usage $0
fi
#------------------------------------------------------------------------------

sdx=$1
tmp_dir=$(mktemp --directory)

function get_kali_old {
    # this kelnel version supports Realtek RTL8812BU USB Wireless Adapter
    wget https://old.kali.org/kali-images/kali-2019.2/kali-linux-2019.2-amd64.iso \
        -P $1
}

function get_kali_latest {
    wget https://kali.download/base-images/kali-2024.2/kali-linux-2024.2-live-amd64.iso \
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

    # https://download.tails.net/tails/stable/tails-amd64-6.7/
    wget https://download.tails.net/tails/stable/tails-amd64-6.7/tails-amd64-6.7.iso
    wget https://download.tails.net/tails/stable/tails-amd64-6.7/tails-amd64-6.7.iso.sig
    TZ=UTC gpg --no-options --keyid-format long --verify tails-amd64-6.7.iso.sig tails-amd64-6.7.iso
    popd
}

get_bliss_os() {
    wget https://kumisystems.dl.sourceforge.net/project/blissos-x86/Official/BlissOSZenith/FOSS/Generic/Bliss-Zenith-v16.9.6-x86_64-OFFICIAL-foss-20240604.iso \
        -P $1
}

mount "/dev/${sdx}" $tmp_dir

mkdir -p ${tmp_dir}/boot/iso

get_kali_old ${tmp_dir}/boot/iso
get_kali_latest ${tmp_dir}/boot/iso
get_tails ${tmp_dir}/boot/iso
get_bliss_os ${tmp_dir}/boot/iso

# based on pendrivelinux.com/downloads/grub.cfg
cp grub.cfg "${tmp_dir}/boot/grub/"

rm -r ${tmp_dir}/boot/iso/tails-signing.key
rm -r ${tmp_dir}/boot/iso/tails-amd64-6.7.iso.sig
rm -r "${tmp_dir}/lost+found/"
umount "/dev/${sdx}"

echo "DONE!"
