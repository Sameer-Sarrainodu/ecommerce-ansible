packer {

  required_plugins {

    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }

    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "azure-arm" "payment" {

  subscription_id = var.subscription_id

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  managed_image_resource_group_name = var.resource_group_name

  managed_image_name = "payment-image"

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
    "source.azure-arm.payment"
  ]

  provisioner "ansible" {

    playbook_file = "../playbooks/packer-payment.yml"
  }
}