variable "cluster_name" {
  description = "Name of the AWS EKS Cluster"
  type        = string
  default     = "datalakehouse-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.110.0.0/16"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the EKS cluster public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "instance_types" {
  description = "Instance types for Spot node group (t3.xlarge recommended for memory)"
  type        = list(string)
  default     = ["t3.xlarge", "m6i.xlarge", "m5.xlarge"]
}

variable "disk_size" {
  description = "Disk size for worker node volumes (GB)"
  type        = number
  default     = 50
}

variable "desired_node_count" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Default resource tags"
  type        = map(string)
  default = {
    Project      = "zarf-uds-lula-datalakehouse"
    Environment  = "dev-aws-eks"
    AutoTeardown = "true"
    ManagedBy    = "opentofu"
    ImpactLevel  = "IL5"
  }
}
