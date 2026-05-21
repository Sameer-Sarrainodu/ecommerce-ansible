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
      "sudo dnf install -y openssh-server python3 openssh-clients",
      "# Fix the SFTP subsystem path for RHEL 9",
      "sudo sed -i 's|^Subsystem.*sftp.*|Subsystem sftp /usr/libexec/openssh/sftp-server|' /etc/ssh/sshd_config",
      "# If the new config exists, use it",
      "if [ -f /etc/ssh/sshd_config.rpmnew ]; then sudo mv /etc/ssh/sshd_config.rpmnew /etc/ssh/sshd_config; fi",
      "# Ensure the correct SFTP path is set",
      "sudo sed -i 's|^Subsystem.*sftp.*|Subsystem sftp /usr/libexec/openssh/sftp-server|' /etc/ssh/sshd_config",
      "# Restart SSH to apply changes",
      "sudo systemctl restart sshd",
      "# Verify the configuration",
      "grep 'Subsystem.*sftp' /etc/ssh/sshd_config",
      "mkdir -p /tmp/.ansible",
      "chmod 777 /tmp/.ansible"
    ]
  }

  provisioner "ansible" {
    playbook_file = "../playbooks/packer-catalogue.yml"
    user = "ec2-user"
    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=../roles",
      "ANSIBLE_REMOTE_TEMP=/tmp/.ansible"
    ]
    extra_arguments = [
      "-e", "ansible_python_interpreter=/usr/bin/python3",
      "-e", "ansible_ssh_transfer_method=scp"
    ]
  }
}