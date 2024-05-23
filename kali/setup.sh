#!/bin/zsh

if [ `id -u` -ne 0 ]
then 
    echo "Please run as root!"
    exit 1
fi

# From apt-cache policy:
# - docker.io=20.10.25+dfsg1-3
packages=(
	keepassxc
	tor
	weechat
	openresolv
	docker.io
	gh
)

passwd kali

pushd /etc/sudoers.d
rm kali-grant-root live
popd

# Change MAC Address
# From Stealing the Network :)
#ifconfig wlan0 hw ether AA:BB:DD:EE:55:11
# FIXME: MAC address is returning to old value
ip link set dev wlan0 address AA:BB:DD:EE:55:11


# Disable ipv6 - ProtonVPN does not support it
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
# remain after reboot
# sysctl -p

# Connect to Wi-Fi
#nmcli dev wifi connect $1 password $2 hidden yes
nmcli c add type wifi con-name "kali_tmp" ifname wlan0 ssid $1
nmcli con modify "kali_tmp" wifi-sec.key-mgmt wpa-psk
nmcli con modify "kali_tmp" wifi-sec.psk $2
nmcli connection up "kali_tmp"
#nmcli connection delete "kali_tmp"

apt update
apt install $packages -y

# ProtonVPN
wget "https://raw.githubusercontent.com/ProtonVPN/scripts/master/update-resolv-conf.sh" -O "/etc/openvpn/update-resolv-conf"
chmod +x "/etc/openvpn/update-resolv-conf"

# git config file
cp -v ./gitconfig /home/kali/.gitconfig
chown kali:kali /home/kali/.gitconfig
runuser -l kali -c 'git config --global --list'

# Connect to the VPN
# Go to https://account.protonvpn.com/account and get username/password

# TODO: Configure Firefox:
# - remove every search engine but DuckGo
# - import burpsuite certificate and enable proxy to 127.0.0.1
