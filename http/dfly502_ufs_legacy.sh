#!/bin/sh
#
# A file like this is typically copied to /usr/local/etc/rconfig/auto.sh on
# the rconfig server and the rconfig demon is run via 'rconfig -s -a'.  When
# you boot the DragonFly CD you have to bring up the network, typically
# via 'dhclient interfacename', then run 'rconfig -a' or
# 'rconfig -a ip_of_server' if the server is not on the same LAN.
#
# WARNING!  THIS SCRIPT WILL COMPLETELY WIPE THE DISK!
#
# $DragonFly: src/share/examples/rconfig/auto.sh,v 1.2 2008/09/03 02:22:25 dillon Exp $

# Use the first disk in kern.disks
#
ndisks=$(sysctl -n kern.disks | wc -w | tr -d ' ')
n=1

while [ ${n} -le ${ndisks} ]
do
    tmpdisk=$(sysctl -n kern.disks | cut -w -f${n})
    case ${tmpdisk} in
	da*|ad*|vbd*)
	    disk=${tmpdisk}
	    ;;
    esac

    if [ ! -z "${disk}" ]; then
	break
    fi

    n=$(( $n + 1 ))
done

export slice=s1
export xdisk=$disk$slice

# Find the network interface to use
#
export interface=$(ifconfig -l | cut -w -f1)

# Wipe the disk entirely
#
dd if=/dev/zero of=/dev/$disk bs=32k count=16
fdisk -IB $disk
boot0cfg -B $disk
boot0cfg -v $disk
dd if=/dev/zero of=/dev/$xdisk bs=32k count=16

# Make the labels
#
disklabel -B -r -w $xdisk auto
disklabel $xdisk > /tmp/disklabel.$xdisk
cat >> /tmp/disklabel.$xdisk <<EOF
a: * * 4.2BSD
b: 512m * swap
EOF
disklabel -R $xdisk /tmp/disklabel.$xdisk
disklabel $xdisk

# Create the filesystem
#
newfs /dev/${xdisk}a

# Enable swap space and dumpdev, there might be not enough mem
# or we may panic and it could be useful to get a dump
#
swapon /dev/${xdisk}b
dumpon /dev/${xdisk}b

# Mount the filesystems
#
mount /dev/${xdisk}a /mnt
mkdir -p /mnt/var
mkdir -p /mnt/tmp
mkdir -p /mnt/usr/local/etc
mkdir -p /mnt/home

# Copy from the LiveCD
#
cpdup -o -vv / /mnt
cpdup -o -vv /var /mnt/var
cpdup -o -vv /etc.hdd /mnt/etc
cpdup -o -vv /dev /mnt/dev
cpdup -o -vv /usr /mnt/usr
cpdup -o -vv /usr/local/etc /mnt/usr/local/etc

# Prepare configuration files
#
cat >/mnt/etc/fstab <<EOF
# Example fstab based on /README.
#
# Device                Mountpoint      FStype  Options         Dump    Pass#
/dev/${xdisk}a		/		ufs	rw		1	1
/dev/${xdisk}b          none            swap    sw              0       0
tmpfs			/tmp		tmpfs	rw		0	0
proc			/proc		procfs	rw		0	0
EOF

cat >/mnt/etc/rc.conf <<EOF
hostname="dragonfly502"
ifconfig_${interface}="DHCP"
sshd_enable="YES"
dntpd_enable="YES"
dumpdev="/dev/${xdisk}b"
EOF

cat >/mnt/boot/loader.conf <<EOF
autoboot_delay="1"
EOF

# Create 'vagrant' user
#
echo 'vagrant' | pw -V /mnt/etc useradd -n vagrant -h 0 -s /bin/sh -G wheel,operator \
		    -u 1001 -d /home/vagrant -c vagrant
mkdir -p /mnt/home/vagrant
chown 1001:1001 /mnt/home/vagrant

# Allow password authentication for ssh connections
#
sed -e 's/PasswordAuthentication no/PasswordAuthentication yes/' < \
    /mnt/etc/ssh/sshd_config > /mnt/etc/ssh/sshd_config.new
mv -f /mnt/etc/ssh/sshd_config.new /mnt/etc/ssh/sshd_config

# Create /vagrant
#
mkdir /mnt/vagrant
chown 1001 /mnt/vagrant

# Install software required
#
cp /etc/resolv.conf /mnt/etc

pkg -c /mnt update
pkg -c /mnt install -y sudo bash rsync

# Configure sudoers
#
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /mnt/usr/local/etc/sudoers.d/wheel
chmod 440 /mnt/usr/local/etc/sudoers.d/wheel
