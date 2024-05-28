#!/bin/zsh

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
	-v "$(dirname $(realpath "$0"))":${HOME}/git_repos \
	-v /dev/bus/usb:/dev/bus/usb \
	liveusb_playground:0.2
