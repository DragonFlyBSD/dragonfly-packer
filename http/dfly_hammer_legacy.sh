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
#set -x

# Use the first disk in kern.disks
#
version=$1
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

# Make the labels
#
disklabel -B -r -w $xdisk auto
disklabel $xdisk > /tmp/disklabel.$xdisk
cat >> /tmp/disklabel.$xdisk <<EOF
a: 768m 0 4.2BSD
b: 1g * swap
d: * * HAMMER
EOF
disklabel -R $xdisk /tmp/disklabel.$xdisk
disklabel $xdisk

# Create the filesystems
#
newfs /dev/${xdisk}a
newfs_hammer -f -L ROOT /dev/${xdisk}d

# Enable swap space and dumpdev, there might be not enough mem
# or we may panic and it could be useful to get a dump
#
swapon /dev/${xdisk}b
dumpon /dev/${xdisk}b

# Mount the filesystems
#
mount /dev/${xdisk}d /mnt
mkdir -p /mnt/boot
mount /dev/${xdisk}a /mnt/boot

# Create PFS mount points for nullfs.
#
# Do the mounts manually so we can install the system, setup
# the fstab later on.
mkdir /mnt/pfs

hammer pfs-master /mnt/pfs/usr
hammer pfs-master /mnt/pfs/usr.obj
hammer pfs-master /mnt/pfs/var
hammer pfs-master /mnt/pfs/var.crash
hammer pfs-master /mnt/pfs/var.tmp
hammer pfs-master /mnt/pfs/home

mkdir -p /mnt/var
mkdir -p /mnt/tmp
mkdir -p /mnt/usr/local/etc
mkdir -p /mnt/home

# Mount NULL mountpoints for copying the files
mount_null /mnt/pfs/usr /mnt/usr
mount_null /mnt/pfs/var /mnt/var
mount_null /mnt/pfs/home /mnt/home

# Copy from the LiveCD
#
cpdup -o -vv / /mnt
cpdup -o -vv /boot /mnt/boot
cpdup -o -vv /var /mnt/var
cpdup -o -vv /etc.hdd /mnt/etc
cpdup -o -vv /usr /mnt/usr
cpdup -o -vv /usr/local/etc /mnt/usr/local/etc

chflags -R nohistory /mnt/var/tmp
chflags -R nohistory /mnt/var/crash
chflags -R nohistory /mnt/usr/obj

# Prepare configuration files
#
cat >/mnt/etc/fstab <<EOF
# Example fstab based on /README.
#
# Device                Mountpoint      FStype  Options         Dump    Pass#
/dev/${xdisk}d		/		hammer	rw		1	1
/dev/${xdisk}a		/boot		ufs	rw		1	1
/dev/${xdisk}b          none            swap    sw              0       0
/pfs/usr		/usr		null	rw		0	0
/pfs/var		/var		null	rw		0	0
/pfs/home		/home		null	rw		0	0
/pfs/var.tmp		/var/tmp	null	rw		0	0
/pfs/usr.obj		/usr/obj	null	rw		0	0
/pfs/var.crash		/var/crash	null	rw		0	0
tmpfs			/tmp		tmpfs	rw		0	0
proc			/proc		procfs	rw		0	0
EOF

cat >/mnt/etc/rc.conf <<EOF
hostname="dragonfly${version}"
ifconfig_${interface}="DHCP"
sshd_enable="YES"
dntpd_enable="YES"
dumpdev="/dev/${xdisk}b"
EOF

cat >/mnt/boot/loader.conf <<EOF
autoboot_delay="1"
vfs.root.mountfrom="hammer:${xdisk}d"
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

#
# There is a bug in pkgng 1.10.1 in which -c <chroot dir> won't work properly.
# Detect if the LiveCD has that version or lower and use a pkg-static from
# bootstrap tools
PKGVER=$(pkg -v | tr -d .)
if [ ${PKGVER} -le 1101 ]; then
    fetch -o /tmp/pkg-static https://monster.dragonflybsd.org/builds/bootstrap/pkg/pkg-static
    chmod +x /tmp/pkg-static
    PKGBIN=/tmp/pkg-static
else
    PKGBIN=/usr/local/sbin/pkg
fi

${PKGBIN} -c /mnt update
${PKGBIN} -c /mnt upgrade -y pkg
${PKGBIN} -c /mnt install -y sudo bash rsync

# Configure sudoers
#
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /mnt/usr/local/etc/sudoers.d/wheel
chmod 440 /mnt/usr/local/etc/sudoers.d/wheel
