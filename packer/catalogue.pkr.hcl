source "azure-arm" "catalogue" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id

  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = "catalogue-image-${formatdate("YYYYMMDDhhmm", timestamp())}"

  os_type         = "Linux"
  image_publisher = "RedHat"
  image_offer     = "RHEL"
  image_sku       = "9-lvm-gen2"
  location        = var.location
  vm_size         = "Standard_D2s_v3"

  azure_tags = {
    Environment = "dev"
    Project     = "roboshop"
  }

  communicator = "ssh"
  ssh_username = "ec2user"          # ← Correct user for Azure RHEL
  ssh_timeout  = "15m"
}

build {
  sources = ["source.azure-arm.catalogue"]

  # ========================================
  # 1. Shell Provisioner - Prepare SSH
  # ========================================
  provisioner "shell" {
    inline = [
      "echo '=== Installing packages ==='",
      "sudo dnf install -y openssh-server openssh-clients python3",

      "echo '=== Enable SSHD ==='",
      "sudo systemctl enable --now sshd",

      "echo '=== Fix SFTP Subsystem (RHEL 9 OpenSSH 9.x) ==='",
      "sudo sed -i '/^Subsystem sftp/d' /etc/ssh/sshd_config",
      "echo 'Subsystem sftp internal-sftp' | sudo tee -a /etc/ssh/sshd_config",

      "echo '=== Restart SSHD ==='",
      "sudo systemctl restart sshd",

      "echo '=== Create Ansible temp dir ==='",
      "sudo mkdir -p /tmp/.ansible",
      "sudo chmod 777 /tmp/.ansible",

      "echo '=== Wait for SSH to stabilize ==='",
      "sleep 15"
    ]
    execute_command = "sudo -E bash -c '{{ .Path }}'"
  }

  # ========================================
  # 2. Ansible Provisioner
  # ========================================
  provisioner "ansible" {
    playbook_file   = "../playbooks/packer-catalogue.yml"
    user            = "azureuser"

    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=../roles",
      "ANSIBLE_REMOTE_TEMP=/tmp/.ansible"
    ]

    extra_arguments = [
      "-e", "ansible_python_interpreter=/usr/bin/python3",
      "-e", "ansible_ssh_transfer_method=smart",
      "--scp-extra-args", "-O",           # ← This is the key for OpenSSH 9+
      "-vvv"                              # For better debugging
    ]
  }
}