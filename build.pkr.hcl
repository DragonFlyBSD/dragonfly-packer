build {
  sources = [
    "source.virtualbox-iso.dfly",
    "source.qemu.dfly",
    "source.hyperv-iso.dfly",
    "source.vmware-iso.dfly"
  ]

  provisioner "shell" {
    scripts = [
      "scripts/cleanup.sh",
      "scripts/vagrant_keys.sh"
    ]
  }

  /*
  post-processors {
   post-processor "vagrant" {
   }
   post-processor "vagrant-cloud" {
     access_token = "${var.cloud_token}"
     box_tag      = "${var.box_tag}"
     version      = "${var.box_version}"
   }
  }
  */
}
