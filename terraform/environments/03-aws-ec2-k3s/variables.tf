variable "aws_region" {
  description = "Target AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Prefix for all resources in this environment"
  type        = string
  default     = "datalakehouse-k3s"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.100.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.100.1.0/24"
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks permitted to access administrative ports (SSH, K8s API)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 Spot instance type (t3.xlarge has 4 vCPU / 16 GB RAM)"
  type        = string
  default     = "t3.xlarge"
}

variable "root_volume_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 50
}

variable "tags" {
  description = "Default resource tags applied to all AWS components"
  type        = map(string)
  default = {
    Project      = "zarf-uds-lula-datalakehouse"
    Environment  = "dev-aws-k3s"
    AutoTeardown = "true"
    ManagedBy    = "opentofu"
    ImpactLevel  = "IL5"
  }
}
