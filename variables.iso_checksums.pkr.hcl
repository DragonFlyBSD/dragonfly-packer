variable "iso_checksums" {
  type = map(string)
  default = {
    "dfly-x86_64-4.6.2_REL.iso" = "md5:1e7670452a39a6c3cc2491a0da860698"
    "dfly-x86_64-6.4.0_REL.iso" = "md5:ff4d500c7c75b1f88ca4237a6aa861d1"
  }
}
