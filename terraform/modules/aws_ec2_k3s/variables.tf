variable "environment_name" {
  description = "Prefix for AWS resources in this environment"
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

variable "availability_zone" {
  description = "AWS Availability Zone for the subnet"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks permitted to access administrative ports (SSH, K8s API)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_type" {
  description = "EC2 Instance Type (t3.xlarge recommended for UDS Core + Lakehouse RAM requirements)"
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
    Project       = "zarf-uds-lula-datalakehouse"
    Environment   = "dev-aws-k3s"
    AutoTeardown  = "true"
    ManagedBy     = "opentofu"
    ImpactLevel   = "IL5"
  }
}
