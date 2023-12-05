variable "dfly_version" {
  type        = string
  description = "A string like 6.4.0"
}

variable "iso_mirror" {
  type = string
}

variable "iso_name" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_checksum" {
  type = string
}

variable "disk_size" {
  type = number
}

variable "headless" {
  type    = bool
  default = true
}

variable "ssh_username" {
  type    = string
  default = "vagrant"
}

variable "ssh_password" {
  type    = string
  default = "vagrant"
}

variable "ssh_timeout" {
  type    = string
  default = "30m"
}

variable "install_script" {
  type = string
}
