source "azure-arm" "catalogue" {

  subscription_id = var.subscription_id

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  managed_image_resource_group_name = var.resource_group_name

  managed_image_name = "catalogue-image"

  os_type         = "Linux"
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9-lvm-gen2"

  location = var.location

  vm_size = "Standard_D2s_v3"

  azure_tags = {
    Environment = "dev"
    Project     = "roboshop"
  }

  communicator = "ssh"

  ssh_username = "ec2-user"
}

build {

  sources = [
    "source.azure-arm.catalogue"
  ]
  provisioner "shell" {

    inline = [
      "sudo dnf install -y openssh-server",
      "sudo ln -s /usr/libexec/openssh/sftp-server /usr/lib/sftp-server || true",
      "mkdir -p /tmp/.ansible",
      "chmod 777 /tmp/.ansible"
    ]
  }

  provisioner "ansible" {

    playbook_file = "../playbooks/packer-catalogue.yml"

    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=../roles",
      "ANSIBLE_REMOTE_TEMP=/tmp/.ansible"
    ]
  }
}