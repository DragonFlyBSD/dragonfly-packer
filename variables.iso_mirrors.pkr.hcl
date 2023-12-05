variable "iso_mirrors" {
  type = map(string)
  default = {
    "us-default" = "https://avalon.dragonflybsd.org/iso-images/"
    "jp-1"       = "https://pub.allbsd.org/DragonFly/iso-images/"
    # "jp-2" = "https://ftp.jaist.ac.jp/pub/DragonFly/iso-images/"
  }
}
