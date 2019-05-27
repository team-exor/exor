#!/bin/bash

setup_lxc() {
	eval echo "%sudo ALL=NOPASSWD: /usr/bin/lxc-start" > /etc/sudoers.d/gitian-lxc
	eval echo "%sudo ALL=NOPASSWD: /usr/bin/lxc-execute" >> /etc/sudoers.d/gitian-lxc
	eval echo "\#!/bin/sh -e" > /etc/rc.local
	eval echo "brctl addbr br0" >> /etc/rc.local
	eval echo "ip addr add 10.0.3.2/24 broadcast 10.0.3.255 dev br0" >> /etc/rc.local
	eval echo "ip link set br0 up" >> /etc/rc.local
	eval echo "firewall-cmd --zone=trusted --add-interface=br0" >> /etc/rc.local
	eval echo "exit 0" >> /etc/rc.local
	eval echo "export USE_LXC=1" >> /home/${1}/.profile
	eval echo "export GITIAN_HOST_IP=10.0.3.2" >> /home/${1}/.profile
	eval echo "export LXC_GUEST_IP=10.0.3.5" >> /home/${1}/.profile
	eval echo "'Defaults timestamp_timeout=-1' | sudo EDITOR='tee -a' visudo"
	chmod +x /etc/rc.local
}

# Verify that user is not root
if [[ "$(whoami)" = "root" ]]
then
	echo "This script cannot be started as the root user. Please switch to the user who will be used for gitian builder and try again." && exit
fi

# Set the current user
CURRENT_USER="$(whoami)"
# Ensure that root user can call the setup_lxc function
export -f setup_lxc
# Download the build script
wget -q "https://raw.githubusercontent.com/team-exor/exor/master/contrib/gitian-build.sh"
# Mark the build script as executable
chmod +x gitian-build.sh
# Install dependencies and generate reboot script as the root user
echo && echo "Please enter the password for root"
su root -c "apt-get update && apt-get install make git ruby sudo apt-cacher-ng qemu-utils debootstrap lxc python-cheetah parted kpartx bridge-utils curl ubuntu-archive-keyring firewalld -y && adduser $CURRENT_USER sudo && setup_lxc $CURRENT_USER && echo && echo 'The system must be rebooted to finish the setup process' && read -p 'Press any key to reboot now' && rm -f $( cd "$(dirname "$0")" ; pwd -P )/${0##*/} && reboot"
