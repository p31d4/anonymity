#!/bin/bash

set -e

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

mount /dev/${sdx}3 ${tmp_dir}
mkdir -p ${tmp_dir}/boot/efi
mount /dev/${sdx}1 ${tmp_dir}/boot/efi
mkdir -p ${tmp_dir}/home
mount /dev/${sdx}4 ${tmp_dir}/home

# Not required in the docker container
#pacman-key --populate
#pacman-key --init

pacman -Syu
pacstrap ${tmp_dir} base linux linux-firmware base-devel grub vim efibootmgr networkmanager
genfstab -U ${tmp_dir} >> ${tmp_dir}/etc/fstab

cp -v /etc/pacman.conf ${tmp_dir}/etc/
cp -rv /etc/pacman.d/* ${tmp_dir}/etc/pacman.d/

read -p "Enter the root password: " -e ROOT_PASS
read -p "Enter the hostname: " -e HOSTNAME
read -p "Enter the username: " -e USERNAME
read -p "Enter the user password: " -e USER_PASS

#cat << EOF | arch-chroot ${tmp_dir}
cat << EOT | tee -a ${tmp_dir}/chroot_script.sh
#!bin/bash
sed -i "s/#en_US.UTF-8/en_US.UTF-8/g" /etc/locale.gen
locale-gen
echo "${HOSTNAME}" | tee -a /etc/hostname
echo "${ROOT_PASS}" | passwd --stdin
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USER_PASS}" | passwd --stdin ${USERNAME}
sed -i "s/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g" /etc/sudoers
grub-install --target=x86_64-efi --force --removable --no-floppy --boot-directory="/boot" --efi-directory="/boot/efi"
grub-install --target=i386-pc --force --removable --no-floppy --boot-directory="/boot" "/dev/${sdx}"
#grub-install "/dev/${sdx}"
grub-mkconfig -o /boot/grub/grub.cfg
sync
pacman -Syu
EOT
#EOF

chmod +x ${tmp_dir}/chroot_script.sh
arch-chroot ${tmp_dir} ./chroot_script.sh

sleep 0.2
rm ${tmp_dir}/chroot_script.sh
sed -i "s/${sdx}/sda/g" ${tmp_dir}/etc/fstab
sync

umount "/dev/${sdx}4"
umount "/dev/${sdx}1"
umount "/dev/${sdx}3"

echo "DONE!"

# Connect to Wi-Fi
#systemctl start NetworkManager
#nmcli c add type wifi con-name "arch_tmp" ifname <IFACE_NAME> ssid <SSID>
#nmcli con modify "arch_tmp" wifi-sec.key-mgmt wpa-psk
#nmcli connection up "arch_tmp" --ask
