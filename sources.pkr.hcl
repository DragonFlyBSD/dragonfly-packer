local "iso_name" {
  expression = "${var.iso_name != "" ? var.iso_name : join("", ["dfly-x86_64-", var.dfly_version, "_REL.iso"])}"
}

local "iso_url" {
  expression = "${var.iso_url != "" ? var.iso_url : join("", [var.iso_mirror, local.iso_name])}"
}

source "virtualbox-iso" "dfly" {
  iso_url       = "${local.iso_url}"
  iso_checksum  = "${var.iso_checksum}"
  guest_os_type = "FreeBSD_64"
  headless      = "${var.headless}"
  disk_size     = "${var.disk_size}"
  boot_wait     = "5s"
  boot_command = [
    "1<wait30s>",
    "root<return><wait5s>",
    "/sbin/dhclient em0<enter><wait10s>",
    "/usr/bin/fetch -o /tmp/install http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.install_script}<enter><wait1s>",
    "/bin/sh /tmp/install ${replace(var.dfly_version, ".", "")} && /sbin/shutdown -r now<enter>"
  ]
  http_directory       = "http"
  shutdown_command     = "/sbin/poweroff"
  ssh_username         = "${var.ssh_username}"
  ssh_password         = "${var.ssh_password}"
  ssh_timeout          = "${var.ssh_timeout}"
  vm_name              = "dfly-${var.dfly_version}"
  hard_drive_interface = "sata"
  guest_additions_mode = "disable"
}
