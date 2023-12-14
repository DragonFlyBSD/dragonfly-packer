#!/bin/sh

# Install a DragonFly system from livecd.
#
# Mostly taken from:
#
# https://gist.github.com/liweitianux/547652a3dd3a853afed71ba50410ffb5
#

01_format_disk() {
    local _disk=$1

    dd if=/dev/zero of=/dev/$_disk bs=32k count=16
    gpt create -f $_disk
    gpt add -t efi     -s  262144 $_disk  # ESP (128 MB)
    gpt add -t ufs     -s 4194303 $_disk  # UFS /boot (2 GB)
    gpt add -t swap    -s 2097152 $_disk  # swap (1 GB)
    gpt add -t hammer2            $_disk  # HAMMER2 (all remainaing space)
}

02_format_fs() {
    local _disk=$1

    newfs_msdos -F 16 -L EFI /dev/${_disk}s0
    newfs -n BOOT            /dev/${_disk}s1         # UFS /boot
    newfs_hammer2 -L ROOT    /dev/${_disk}s3         # HAMMER2 /
}

03_mount_and_init_fs() {
    local _disk=$1
    local _mnt=$2

    mount           /dev/${_disk}s3@ROOT    $_mnt
    hammer2 -s $_mnt pfs-create HOME
    hammer2 -s $_mnt pfs-create BUILD

    cd $_mnt

    mkdir -p   boot
    mount -t ufs    /dev/${_disk}s1     boot

    mkdir -p boot/efi
    mount -t msdos  /dev/${_disk}s0     boot/efi

    mkdir -p   home
    mount      /dev/${_disk}s3@HOME     home

    mkdir -p   build
    mount      /dev/${_disk}s3@BUILD    build

    mkdir -p   build/usr.obj   usr/obj
    mount_null build/usr.obj   usr/obj

    mkdir -p   build/var.cache var/cache
    mount_null build/var.cache var/cache

    mkdir -p   build/var.crash var/crash
    mount_null build/var.crash var/crash

    mkdir -p   build/var.log   var/log
    mount_null build/var.log   var/log

    mkdir -p   build/var.spool var/spool
    mount_null build/var.spool var/spool
}

04_create_fs_layout() {
    local _mnt=$1

    mtree -deU -f /etc/mtree/BSD.root.dist    -p $_mnt
    mtree -deiU -f /etc/mtree/BSD.var.dist    -p $_mnt/var
    mtree -deU -f /etc/mtree/BSD.usr.dist     -p $_mnt/usr
    mtree -deU -f /etc/mtree/BSD.include.dist -p $_mnt/usr/include
}

05_copy_system() {
    local _mnt=$1

    # On the livecd, each of the following are separate mount points:
    cpdup -vI /        $_mnt
    cpdup -vI /root    $_mnt/root
    cpdup -vI /boot    $_mnt/boot
    cpdup -vI /var     $_mnt/var
    cpdup -vI /var/log $_mnt/var/log
    cpdup -vI /usr/local/etc $_mnt/usr/local/etc

    cd $_mnt
    rm -rf README* autorun* dflybsd.ico index.html
    rm -rf etc # should not be neccessary!
    mv etc.hdd etc
}

05_copy_system_post() {
    local _mnt=$1
    #(cd $_mnt && ln -s usr/src/sys sys)
    (cd $_mnt/etc/ssl && ln -s ../../usr/local/share/certs/ca-root-nss.crt cert.pem)
}

06_config_boot() {
    local _disk=$1
    local _mnt=$2

    local _part_root=`map_partition_to_serno ${_disk}s3`

    cat > $_mnt/boot/loader.conf << _EOF_
autoboot_delay="1"
vfs.root.mountfrom="hammer2:/dev/${_part_root}@ROOT"
_EOF_

    mkdir -p $_mnt/boot/efi/EFI/BOOT
    cp /boot/boot1.efi $_mnt/boot/efi/EFI/BOOT/BOOTX64.efi

    # optional
    mkdir -p $_mnt/boot/efi/dragonfly
    cp /boot/boot1.efi $_mnt/boot/efi/dragonfly/
}

06_config_fstab() {
    local _disk=$1
    local _mnt=$2
    local _part_root=`map_partition_to_serno ${_disk}s3`
    local _part_boot=`map_partition_to_serno ${_disk}s1`
    local _part_efi=`map_partition_to_serno ${_disk}s0`
    local _part_swap=`map_partition_to_serno ${_disk}s2`

    cat > $_mnt/etc/fstab << _EOF_
# Device			    Mountpoint  FStype	Options		Dump	Pass#
/dev/${_part_root}@ROOT	/		    hammer2	rw		1	1
/dev/${_part_root}@HOME	/home		hammer2	rw		2	2
/dev/${_part_root}@BUILD	/build		hammer2	rw		2	2
/dev/${_part_boot}			/boot		ufs     rw		2	2
/dev/${_part_efi}			/boot/efi	msdos	rw,noauto	2	2
/dev/${_part_swap}			none		swap	sw		0	0
/build/usr.obj			/usr/obj	null	rw		0	0
/build/var.cache		/var/cache	null	rw		0	0
/build/var.crash		/var/crash	null	rw		0	0
/build/var.log			/var/log	null	rw		0	0
/build/var.spool		/var/spool	null	rw		0	0
proc				    /proc		procfs	rw		0	0
_EOF_
}

06_config_rc_conf() {
    local _disk=$1
    local _mnt=$2
    local _hostname=$3

    local _part_swap=`map_partition_to_serno ${_disk}s2`

    cat >> $_mnt/etc/rc.conf << _EOF_
dumpdev="/dev/${_part_swap}"
hostname="${_hostname}"
tmpfs_tmp="YES"
tmpfs_var_run="YES"
dhcpcd_enable="YES"
sshd_enable="YES"
sshd_flags="-o PermitRootLogin=yes -o PasswordAuthentication=yes" # REMOVE-ME-AFTER-INSTALL
dntpd_enable="YES"
powerd_enable="YES"
_EOF_
}

06_config_userdb() {
    local _mnt=$1
    pwd_mkdb -p -d $_mnt/etc $_mnt/etc/master.passwd
    pw -V $_mnt/etc userdel installer
}

07_change_password() {
    local _mnt=$1
    local _user=$2
    local _password=$3

    echo "${_password}" | chroot $_mnt pw usermod $_user -h 0
}

07_change_shell() {
    local _mnt=$1
    local _user=$2
    local _shell=$3

    chroot $_mnt pw usermod $_user -s ${_shell}
}

map_partition_to_serno() {
    local _part=$1
    local _serno

    for _serno in `find /dev/serno -type c`; do
        if [ `stat -f %Z /dev/${_part}` == `stat -f %Z ${_serno}` ]; then
            # same device
            echo $_serno | cut -d / -f 3-
            return
        fi
    done

    echo ${_part}
}

do_install() {
    local _disk=$1
    local _mnt=$2

    mkdir -p $_mnt

    01_format_disk $_disk
    02_format_fs $_disk
    03_mount_and_init_fs $_disk $_mnt
    04_create_fs_layout $_mnt
    05_copy_system  $_mnt
    05_copy_system_post  $_mnt
    06_config_boot  $_disk $_mnt
    06_config_fstab $_disk $_mnt
    06_config_rc_conf $_disk $_mnt dragonfly
    06_config_userdb $_mnt
    07_change_password $_mnt root toor
    # /bin/sh is somehow required as root-shell, otherwise packer fails to execute `chmod` (maybe wrong path?)
    07_change_shell $_mnt root /bin/sh
}

do_reboot() {
    local _nextboot=$1

    # NOTE: Ejecting livecd via camcontrol eject cd0 does not work. it hangs during shutdown
    kldload efirt # efibootmgr needs this!
    # Boot order is CD, HD so make HD the nextBoot (permanent?)
    efibootmgr -b $_nextboot -n
    shutdown -r now
}

_cmd=$1
case "${_cmd}" in
install)
    _disk=$2
    do_install $_disk /tmp/rootmnt
    ;;
reboot)
    _nextboot=$2
    do_reboot $_nextboot
    ;;
*)
    echo "Unknown command: ${_cmd}"
    exit 1
    ;;
esac
