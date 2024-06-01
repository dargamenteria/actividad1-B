#resource "libvirt_pool" "pools" {
#  name = "pools"
#  type = "dir"
#  path = var.libvirt_disk_path
#}
#
resource "libvirt_volume" "kvm_docker_vol" {
  for_each = var.vm_hostnames
  name     = "kvm_${each.key}-qcow2"
  pool     = "pools" #libvirt_pool.pools.name
  source   = var.kmv_image
  format   = "qcow2"
}

data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.yml")
}

data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  for_each       = var.vm_hostnames
  name           = "commoninit_${each.key}.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = "pools" # libvirt_pool.pools.name
}

resource "libvirt_domain" "domain-kvm" {
  for_each = var.vm_hostnames

  name   = each.key
  memory = "1024"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = each.key
    bridge         = "br0"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.kvm_docker_vol[each.key].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }



}

resource "null_resource" "provisioner" {
  for_each = var.vm_hostnames
  provisioner "remote-exec" {
    #script = "${path.module}/provisioner.sh"
    inline = [
      "sudo resolvectl dns ens3 1.1.1.1",
      "sudo resolvectl dns ens3 1.1.1.1 ${each.key}",
      "sudo apt update -y",
      "sudo apt install -y cloud-guest-utils",
      "sudo growpart /dev/vda 1",
      "sudo apt install -y ca-certificates curl python3-flask junit flake8 python3-flake8 bandit python3-bandit python3-pip",
      "sudo pip3 install coverage",
      "sudo mkdir -p /apps/wiremock",
      "sudo curl --create-dirs -O --output-dir /apps/wiremock https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.5.4/wiremock-standalone-3.5.4.jar",
      "sudo chmod -R 755 /apps/wiremock",
      "sudo chmod +x  /apps/wiremock/wiremock-standalone-3.5.4.jar",


    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      host        = libvirt_domain.domain-kvm[each.key].network_interface[0].addresses[0]
      private_key = file(var.ssh_private_key)
      timeout     = "2m"
    }
  }

  depends_on = [libvirt_domain.domain-kvm]
}


