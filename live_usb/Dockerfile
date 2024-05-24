# Ubuntu 22.04 choosed because of Kicksecure OS
FROM ubuntu:22.04

RUN export TERM=xterm-256color

RUN apt update

# versions got from apt-cache policy <package>
RUN apt install -y vim=2:8.2.3995-1ubuntu2.17 \
        git=1:2.34.1-1ubuntu1.11 \
        wget=1.21.2-2ubuntu1 \
        grub2=2.06-2ubuntu7.2

# Dependencies to build grub
RUN apt install -y python3=3.10.6-1~22.04
RUN apt install -y grub-efi=2.06-2ubuntu7.2
RUN apt install -y autoconf=2.71-2
RUN apt install -y autopoint=0.21-4ubuntu4
RUN apt install -y pkg-config=0.29.2-1ubuntu3
RUN apt install -y build-essential=12.9ubuntu3
RUN apt install -y bison=2:3.8.2+dfsg-1build1
RUN apt install -y flex=2.6.4-8build2
RUN apt install -y gawk=1:5.1.0-1ubuntu0.1

# TODO: find out which deb pkg had the i386 grub stuff
# using bash only because of pushd and popd
RUN bash -xc "\
        mkdir /tmp/git_repos && cd /tmp/git_repos && \
        git clone git://git.savannah.gnu.org/grub.git && \
        cd /tmp/git_repos/grub && ./bootstrap && \
        mkdir EFI32 && pushd ./EFI32/ && \
        ../configure --target=i386 --with-platform=efi && make && popd \
        "
