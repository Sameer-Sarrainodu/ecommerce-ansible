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