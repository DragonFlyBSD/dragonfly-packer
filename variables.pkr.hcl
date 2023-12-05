variable "dfly_version" {
  type        = string
  description = "A string like 6.4.0"
}

variable "iso_mirror_location" {
  type    = string
  default = "us-default"
}

variable "iso_mirror" {
  type    = string
  default = ""
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
  type    = string
  default = ""
}

variable "disk_size" {
  type    = number
  default = 50000
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

variable "login_prompt_time" {
  type        = string
  default     = ""
  description = "Number of seconds until the login: prompt appears"
}

variable "install_script" {
  type = string
}
