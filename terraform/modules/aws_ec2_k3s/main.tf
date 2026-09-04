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

# ---------------------------------------------------------------------------------------------------------------------
# VPC & NETWORKING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_vpc" "k3s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.environment_name}-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = merge(var.tags, {
    Name = "${var.environment_name}-igw"
  })
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = merge(var.tags, {
    Name = "${var.environment_name}-public-subnet"
  })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k3s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.environment_name}-public-rt"
  })
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "k3s_sg" {
  name        = "${var.environment_name}-sg"
  description = "Security group for ephemeral K3s Data Lakehouse instance"
  vpc_id      = aws_vpc.k3s_vpc.id

  # SSH Access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Kubernetes API
  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP / HTTPS Ingress for Lakehouse Services & UDS Ingress
  ingress {
    description = "HTTP Ingress"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS Ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # MinIO & Custom ports for direct access
  ingress {
    description = "MinIO Direct S3 & Console"
    from_port   = 9000
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Self-referencing intra-node / cluster traffic
  ingress {
    description = "Self-referencing intra-node traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Outbound Internet Access (for packaging/updates)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment_name}-sg"
  })
}

# ---------------------------------------------------------------------------------------------------------------------
# SSH KEY PAIR
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "k3s_ssh_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "k3s_keypair" {
  key_name   = "${var.environment_name}-key"
  public_key = tls_private_key.k3s_ssh_key.public_key_openssh

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# SPOT EC2 INSTANCE WITH K3S BOOTSTRAP
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    
    # 1. Update OS packages
    apt-get update -y
    apt-get install -y curl wget unzip jq git
    
    # 2. Get Public IP for K3s SAN
    PUBLIC_IP=$(curl -s http://checkip.amazonaws.com || curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "127.0.0.1")
    PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo "127.0.0.1")
    
    # 3. Install K3s (disable Traefik to allow Istio / UDS Core ingress gateway)
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --tls-san $${PUBLIC_IP} --tls-san $${PRIVATE_IP} --disable traefik --write-kubeconfig-mode 644" sh -
    
    # 4. Wait for node to be ready
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    until kubectl get nodes | grep -q " Ready"; do
      sleep 3
    done
    
    # 5. Install Zarf and UDS CLI
    curl -s https://api.github.com/repos/zarf-dev/zarf/releases/latest | jq -r '.assets[] | select(.name | contains("zarf_v") and contains("Linux_amd64") and (contains(".tar.gz") | not)) | .browser_download_url' | head -n 1 | xargs -I {} curl -Lo /usr/local/bin/zarf {}
    chmod +x /usr/local/bin/zarf || true
    
    curl -s https://api.github.com/repos/defenseunicorns/uds-cli/releases/latest | jq -r '.assets[] | select(.name | contains("uds-cli_v") and contains("Linux_amd64") and (contains(".tar.gz") | not)) | .browser_download_url' | head -n 1 | xargs -I {} curl -Lo /usr/local/bin/uds {}
    chmod +x /usr/local/bin/uds || true

    echo "K3s and toolchain bootstrap complete!" > /var/log/bootstrap.status
  EOF
}

resource "aws_spot_instance_request" "k3s_spot_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  spot_type                   = "one-time"
  wait_for_fulfillment        = true
  key_name                    = aws_key_pair.k3s_keypair.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  associate_public_ip_address = true
  user_data                   = local.user_data

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, {
    Name = "${var.environment_name}-spot-node"
  })
}

resource "aws_ec2_tag" "spot_instance_tags" {
  for_each    = merge(var.tags, { Name = "${var.environment_name}-spot-node" })
  resource_id = aws_spot_instance_request.k3s_spot_node.spot_instance_id
  key         = each.key
  value       = each.value
}
