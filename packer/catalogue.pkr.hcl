source "azure-arm" "catalogue" {
  subscription_id                 = var.subscription_id
  client_id                       = var.client_id
  client_secret                   = var.client_secret
  tenant_id                       = var.tenant_id

  managed_image_resource_group_name = var.resource_group_name
  managed_image_name              = "catalogue-image"

  os_type                         = "Linux"
  image_publisher                 = "RedHat"
  image_offer                     = "RHEL"
  image_sku                       = "9-lvm-gen2"
  location                        = var.location
  vm_size                         = "Standard_D2s_v3"

  azure_tags = {
    Environment = "dev"
    Project     = "roboshop"
  }

  communicator                    = "ssh"
  ssh_username                    = "ec2user" 
  ssh_timeout                     = "10m"
}

build {
  sources = ["source.azure-arm.catalogue"]

  # =============================================
  # First Provisioner: System Preparation
  # =============================================
  provisioner "shell" {
    inline = [
      "echo '=== Updating and Installing Required Packages ==='",
      "sudo dnf install -y openssh-server openssh-clients python3",

      "echo '=== Enabling and Starting SSHD ==='",
      "sudo systemctl enable --now sshd",

      "echo '=== Fixing SFTP Subsystem for RHEL 9 (Long-term Fix) ==='",
      "sudo sed -i 's|^Subsystem sftp.*|Subsystem sftp internal-sftp|' /etc/ssh/sshd_config",

      "echo '=== Restarting SSHD ==='",
      "sudo systemctl restart sshd",

      "echo '=== Creating Ansible Temp Directory ==='",
      "sudo mkdir -p /tmp/.ansible",
      "sudo chmod 777 /tmp/.ansible"
    ]
    execute_command = "sudo -E bash -c '{{ .Path }}'"
  }

  # =============================================
  # Ansible Provisioner
  # =============================================
  provisioner "ansible" {
    playbook_file = "../playbooks/packer-catalogue.yml"
    user          = "azureuser"

    ansible_env_vars = [
      "ANSIBLE_ROLES_PATH=../roles",
      "ANSIBLE_REMOTE_TEMP=/tmp/.ansible"
    ]

    extra_arguments = [
      "-e", "ansible_python_interpreter=/usr/bin/python3",
      "-e", "ansible_ssh_transfer_method=smart",     # Best option
      "--scp-extra-args", "-O"                       # Helps with newer OpenSSH
    ]
  }
}