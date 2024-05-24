#!/bin/zsh

if [ "$#" -ne 1  ] || ! [ -d $1  ]
then
    echo "usage: $0 <git_repos DIR>" >&2
    exit 1
fi

# on Ubuntu
#-v "$XAUTHORITY:/tmp/.XAuthority:rw"
# on Kali
#--volume="${XAUTHORITY:-$HOME/.Xauthority}:/root/.XAuthority:rw"

docker run --rm --privileged --init -it \
	--env "TERM=xterm-256color" --net=host \
	--volume="${XAUTHORITY:-$HOME/.Xauthority}:/root/.XAuthority:rw" \
	-e XAUTHORITY=/root/.XAuthority \
	-e DISPLAY=$DISPLAY \
	-v /tmp/.X11-unix:/tmp/.X11-unix \
	-v /dev/bus/usb:/dev/bus/usb \
	-v "$1":${HOME}/git_repos \
	liveusb_playground:0.1
