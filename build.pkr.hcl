build {
  sources = [
    "source.virtualbox-iso.dfly",
    "source.qemu.dfly",
    "source.hyperv-iso.dfly",
    "source.vmware-iso.dfly"
  ]

  provisioner "shell" {
    scripts = [
      "scripts/01_secure_sshd_config.sh",
      "scripts/02_upgrade_packages.sh",
      "scripts/03_setup_sudo.sh",
      "scripts/04_create_vagrant_user.sh",
      "scripts/05_install_additional_packages.sh"
    ]
  }

  post-processors {
    post-processor "vagrant" {
    }
    /*
   post-processor "vagrant-cloud" {
     access_token = "${var.vagrant_cloud_token}"
     box_tag      = "${var.box_tag}"
     version      = "${var.box_version}"
   }
   */
  }
}
