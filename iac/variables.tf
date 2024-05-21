variable "libvirt_disk_path" {
  type        = string
  description = "path for libvirt pool"
  default     = "/files/vrt/libvirt/pools/"
}

variable "kmv_image" {
  type        = string
  description = "ubuntu image"
  default     = "/files/vrt/libvirt/pools/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "vm_hostname" {
  type        = string
  description = "vm hostname"
  default     = "kvm_docker"
}

variable "ssh_username" {
  type        = string
  description = "the ssh user to use"
  default     = "ubuntu"
}

variable "ssh_private_key" {
  type        = string
  description = "the private key to use"
  default     = "~/.ssh/id_rsa"
}

variable "vm_hostnames" {
  type        = map(string)
  description = "A map with the hostnames"
  default = {
    slave1 = "slave1"
    slave2 = "slave2"
  }
}
