build {
  sources = [
    "source.virtualbox-iso.dfly",
    "source.qemu.dfly"
  ]

  provisioner "shell" {
    scripts = [
      "scripts/cleanup.sh",
      "scripts/vagrant_keys.sh"
    ]
  }
}
