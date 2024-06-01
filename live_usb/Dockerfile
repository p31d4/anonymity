FROM archlinux:latest

# Dirty fix for the case a proxy is giving you a bad time with certificates
#RUN cd /tmp && curl -k https://archlinux.org/mirrorlist/all/ -o mirrorlist && \
#        sed -i '/https/d' mirrorlist && sed -i 's/^#Ser/Ser/g' mirrorlist && \
#        cp mirrorlist /etc/pacman.d/mirrorlist

RUN echo "Y" | pacman -Syu

# https://archlinux.org/packages/
RUN echo "Y" | pacman -Sy vim grub parted dosfstools e2fsprogs wget ntfs-3g wimlib arch-install-scripts

RUN curl -L "https://github.com/WoeUSB/WoeUSB/releases/download/v5.2.4/woeusb-5.2.4.bash" -o /usr/bin/woeusb && \
        chmod +x /usr/bin/woeusb
