#!/usr/bin/env bash
#
# iCEcube2 FlexLM fix
#
# somehow flexLM expects eth0 to be the only valid name to check for the MAC
# most modern distribution use a different naming scheme.
# accepts arbitrary mac-addresses, might also fix other problems, VMs and stuff.
#

sudo modprobe dummy
sudo ip link add eth0 type dummy
sudo ifconfig eth0 up
sudo ifconfig eth0 hw ether 11:22:11:22:11:22
