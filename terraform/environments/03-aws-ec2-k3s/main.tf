terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "k3s_sandbox" {
  source = "../../modules/aws_ec2_k3s"

  environment_name    = var.environment_name
  vpc_cidr            = var.vpc_cidr
  subnet_cidr         = var.subnet_cidr
  allowed_cidr_blocks = var.allowed_cidr_blocks
  instance_type       = var.instance_type
  root_volume_size    = var.root_volume_size
  tags                = var.tags
}

# Workspace-isolated private key for SSH access
resource "local_file" "ssh_private_key" {
  filename        = "${path.module}/.terraform/id_ed25519"
  file_permission = "0600"
  content         = module.k3s_sandbox.ssh_private_key
}

# Workspace-isolated known_hosts file
resource "local_file" "known_hosts" {
  filename        = "${path.module}/.terraform/known_hosts"
  file_permission = "0600"
  content         = "${module.k3s_sandbox.public_ip} ${trimspace(module.k3s_sandbox.ssh_public_key)}\n"
}
