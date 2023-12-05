build {
  sources = [
    "source.virtualbox-iso.dfly"
  ]

  provisioner "shell" {
    scripts = [
      "scripts/cleanup.sh",
      "scripts/vagrant_keys.sh"
    ]
  }
}
