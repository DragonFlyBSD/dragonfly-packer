local "iso_mirror" {
  expression = "${var.iso_mirror != "" ? var.iso_name : lookup(var.iso_mirrors, var.iso_mirror_location, "")}"
}

local "iso_name" {
  expression = "${var.iso_name != "" ? var.iso_name : join("", ["dfly-x86_64-", var.dfly_version, "_REL.iso"])}"
}

local "iso_url" {
  expression = "${var.iso_url != "" ? var.iso_url : join("", [local.iso_mirror, local.iso_name])}"
}

local "iso_checksum" {
  expression = "${var.iso_checksum != "" ? var.iso_checksum : lookup(var.iso_checksums, local.iso_name, "")}"
}

source "virtualbox-iso" "dfly" {
  iso_url       = "${local.iso_url}"
  iso_checksum  = "${local.iso_checksum}"
  guest_os_type = "FreeBSD_64"
  headless      = "${var.headless}"
  disk_size     = "${var.disk_size}"
  boot_wait     = "5s"
  boot_command = [
    "1<wait${var.login_prompt_time != "" ? var.login_prompt_time : "50s"}>",
    "root<enter><wait5s>",
    "/sbin/dhclient em0<enter><wait10s>",
    "/usr/bin/fetch -o /tmp/install http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.install_script}<enter><wait1s>",
    "/bin/sh /tmp/install install da0 && /bin/sh /tmp/install reboot 0002<enter>"
  ]
  firmware             = "efi"
  http_directory       = "http"
  shutdown_command     = "/sbin/poweroff"
  ssh_username         = "${var.ssh_username}"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "${var.ssh_timeout}"
  vm_name              = "dfly-${var.dfly_version}"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"
}

source "qemu" "dfly" {
  iso_url      = "${local.iso_url}"
  iso_checksum = "${local.iso_checksum}"
  format       = "qcow2"
  headless     = "${var.headless}"
  disk_size    = "${var.disk_size}"
  boot_wait    = "3s"
  boot_command = [
    "1<wait${var.login_prompt_time != "" ? var.login_prompt_time : "70s"}>",
    "root<enter><wait5s>",
    "/sbin/dhclient vtnet0<enter><wait10s>",
    "/usr/bin/fetch -o /tmp/install http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.install_script}<enter><wait1s>",
    "/bin/sh /tmp/install install vbd0 && /bin/sh /tmp/install reboot 0003<enter>"
  ]
  http_directory   = "http"
  shutdown_command = "/sbin/poweroff"
  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "${var.ssh_timeout}"
  vm_name          = "dfly-${var.dfly_version}"
  net_device       = "virtio-net"
  disk_interface   = "virtio"

  # Download from here:
  # https://www.kraxel.org/repos/jenkins/edk2/
  # Or read: https://wiki.freebsd.org/UEFI
  efi_boot          = true
  efi_firmware_code = "/usr/local/share/OVMF/OVMF_CODE-pure-efi.fd"
  efi_firmware_vars = "/usr/local/share/OVMF/OVMF_VARS-pure-efi.fd"
}

source "hyperv-iso" "dfly" {
  iso_url      = "${local.iso_url}"
  iso_checksum = "${local.iso_checksum}"
  disk_size    = "${var.disk_size}"
  boot_wait    = "7s"
  boot_command = [
    "1<wait${var.login_prompt_time != "" ? var.login_prompt_time : "50s"}>",
    "root<enter><wait5s>",
    "/sbin/dhclient de0<enter><wait10s>",
    "/usr/bin/fetch -o /tmp/install http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.install_script}<enter><wait1s>",
    "/bin/sh /tmp/install ad0 && /sbin/shutdown -r now<enter>"
  ]
  http_directory   = "http"
  shutdown_command = "/sbin/poweroff"
  network_legacy   = true
  ssh_username     = "${var.ssh_username}"
  ssh_password     = "${var.ssh_password}"
  ssh_timeout      = "${var.ssh_timeout}"
  vm_name          = "dfly-${var.dfly_version}"
}

source "vmware-iso" "dfly" {
  iso_url       = "${local.iso_url}"
  iso_checksum  = "${local.iso_checksum}"
  guest_os_type = "freebsd-64"
  headless      = "${var.headless}"
  disk_size     = "${var.disk_size}"
  boot_wait     = "7s"
  boot_command = [
    "1<wait${var.login_prompt_time != "" ? var.login_prompt_time : "50s"}>",
    "root<enter><wait5s>",
    "/sbin/dhclient em0<enter><wait10s>",
    "/usr/bin/fetch -o /tmp/install http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.install_script}<enter><wait1s>",
    "/bin/sh /tmp/install ${replace(var.dfly_version, ".", "")} && /sbin/shutdown -r now<enter>"
  ]
  http_directory   = "http"
  shutdown_command = "/sbin/poweroff"
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_wait_timeout = "${var.ssh_timeout}"
  vm_name          = "dfly-${var.fly_version}"
}
