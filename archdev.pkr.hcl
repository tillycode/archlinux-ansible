packer {
  required_plugins {
    incus = {
      source  = "github.com/bketelsen/incus"
      version = "~> 1"
    }
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "incus" "archlinux" {
  image           = "images:archlinux"
  output_image    = "archdev"
  container_name  = "packer-archdev"
  virtual_machine = true
  launch_config = {
    "security.secureboot" = "false"
  }
  # skip_publish = true
}

build {
  sources = ["incus.archlinux"]

  provisioner "ansible" {
    pause_before  = "5s"
    playbook_file = "${path.root}/prepare.yml"
    # extra_arguments = [ "-vvv" ]
    inventory_file = "${path.root}/inventory.ini"
  }
}
